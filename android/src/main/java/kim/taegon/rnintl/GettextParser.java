/**
 * Created by taggon
 */
package kim.taegon.rnintl;

import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.HashMap;
import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;
import java.nio.ByteBuffer;

public class GettextParser {
    public final static long MAGIC_NUMBER = 0x950412DEL;
    public final static long LE_MAGIC_NUMBER = 0xDE120495L;
    public final static long UINT = 0xffffffffL;

    protected String lastError = "";
    protected Map<String, Object> catalog = new HashMap<>();
    protected boolean isLittleEndian = false;

    public GettextParser(String filepath) {
        loadFile(filepath);
    }

    public GettextParser(InputStream stream) {
        loadFile(stream);
    }

    public boolean loadFile(String filepath) {
        try {
            InputStream stream = new FileInputStream(filepath);
            loadFile(stream);
            stream.close();
        } catch (Exception e) {
            lastError = e.getMessage();
            return false;
        }

        return true;
    }

    public boolean loadFile(InputStream stream) {
        Map<String, String> headers = new HashMap<>();
        Map<String, String[]> translations = new HashMap<>();

        try {
            DataInputStream ds = new DataInputStream(stream);

            Map<String, Integer> fileHeader = readFileHeader(ds);

            for (int i = 0; i < fileHeader.get("stringCount"); i++) {
                // msgid - original string
                String[] idList = getStringsFromFile(ds, fileHeader.get("originalStringOffset") + i * 8);

                // msgstr - translation string
                String[] translationList = getStringsFromFile(ds, fileHeader.get("translationStringOffset") + i * 8);

                if (idList.length == 1 && idList[0].isEmpty()) {
                    headers = parseHeader(translationList[0]);
                    continue;
                }

                for (String msgid: idList) {
                    translations.put(msgid, translationList);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            lastError = e.getMessage();
            return false;
        }

        catalog.put("headers", headers);
        catalog.put("translations", translations);

        return true;
    }

    protected Map<String, Integer> readFileHeader(DataInputStream ds) throws Exception {
        Map<String, Integer> header = new HashMap<>();
        long magicNumber = 0;

        try {
            // reset the position
            ds.reset();

            // magic number
            magicNumber = ds.readInt() & UINT;

            if (magicNumber != MAGIC_NUMBER && magicNumber != LE_MAGIC_NUMBER) {
                throw new Exception("Invalid magic number");
            }

            // little endian?
            isLittleEndian = (magicNumber == LE_MAGIC_NUMBER);

            // revision
            header.put("revision", swapInteger(ds.readInt()));

            // string count
            header.put("stringCount", swapInteger(ds.readInt()));

            // original string offset
            header.put("originalStringOffset", swapInteger(ds.readInt()));

            // translation string offset
            header.put("translationStringOffset", swapInteger(ds.readInt()));

            // hash table size
            header.put("hashTableSize", swapInteger(ds.readInt()));

            // hash table offset
            header.put("hashTableOffset", swapInteger(ds.readInt()));
        } catch(Exception e) {
            throw e;
        }

        return header;
    }

    final protected int swapInteger(int n) {
        if (isLittleEndian) {
            byte[] b = ByteBuffer.allocate(4).putInt(n).array();
            n = ((b[3]&0xff)<<24) + ((b[2]&0xff)<<16) + ((b[1]&0xff)<<8) + (b[0]&0xff);
        }
        return n;
    }

    protected String[] getStringsFromFile(DataInputStream ds, int offset) {
        List<String> result = new ArrayList<>();
        int len = 0, pos = 0;

        try {
            ds.reset();
            ds.skip(offset);
            len = swapInteger(ds.readInt());
            pos = swapInteger(ds.readInt());

            byte[] data = new byte[len];
            ds.reset();
            ds.skip(pos);
            ds.read(data);

            // strip context
            int contextSeparatorPos = -1;
            for (int i = 0; i < data.length; i++) {
                if (data[i] == 4) {
                    contextSeparatorPos = i;
                    break;
                }
            }
            if (contextSeparatorPos > -1) {
                len -= contextSeparatorPos;
                data = Arrays.copyOfRange(data, contextSeparatorPos+1, len);
            }

            int nullSeparatorPos = 0;
            do {
                nullSeparatorPos = -1;
                for (int i = 0; i < data.length; i++) {
                    if (data[i] == 0) {
                        nullSeparatorPos = i;
                        break;
                    }
                }
                if (nullSeparatorPos < 0) break;

                String str = new String(Arrays.copyOfRange(data, 0, nullSeparatorPos), StandardCharsets.UTF_8);
                result.add(str);

                data = Arrays.copyOfRange(data, nullSeparatorPos+1, data.length);
            } while(true);

            if (result.size() == 0 && data.length == 0) {
                result.add("");
            } else if (data.length > 0) {
                String str = new String(data, StandardCharsets.UTF_8);
                result.add(str);
            }
        } catch (Exception e) {
            lastError = e.getMessage();
            return null;
        }

        return result.toArray(new String[result.size()]);
    }

    public Map<String, String> parseHeader(String headerString) {
        String[] headers = headerString.split("\\n");
        Map<String, String> result = new HashMap<>();

        for(String header: headers) {
            String[] entry = header.split("\\s*:\\s*", 2);
            if (entry.length < 2) continue;

            result.put(entry[0], entry[1]);
        }

        return result;
    }

    public Map<String, Object> getCatalog() {
        return catalog;
    }
}
