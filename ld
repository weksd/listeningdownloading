import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.channels.Channels;
import java.nio.channels.ReadableByteChannel;
import java.awt.Desktop;
public class Main {
    private static final String IN_FILE_TXT = "in.txt";
    private static final String PATH_TO_MUSIC = "music";
    private static final String MP3_EXTENSION = ".mp3";
    public static void main(String[] args) {
        File musicDir = new File(PATH_TO_MUSIC);
        if (!musicDir.exists()) {
            if (musicDir.mkdirs()) {
                System.out.println("Создана директория для музыки: " + PATH_TO_MUSIC);
            } else {
                System.err.println("Ошибка: Не удалось создать директорию для музыки: " + PATH_TO_MUSIC);
                return;
            }
        }
        BufferedReader musicUrlReader = null;
        int count = 0;
        try {
            System.out.println("Начинаем скачивание музыки из файла: " + IN_FILE_TXT + "...");
            musicUrlReader = new BufferedReader(new FileReader(IN_FILE_TXT));
            String musicUrlString;
            while ((musicUrlString = musicUrlReader.readLine()) != null) {
                musicUrlString = musicUrlString.trim();
                if (musicUrlString.isEmpty()) {
                    continue;
                }
                count++;
                String fileName = "track_" + count + MP3_EXTENSION;
                String fullPathFileName = PATH_TO_MUSIC + File.separator + fileName;
                File downloadedFile = new File(fullPathFileName);
                System.out.print("Скачиваю: " + musicUrlString + " -> " + fullPathFileName + "... ");
                try {
                    downloadUsingNIO(musicUrlString, fullPathFileName);
                    System.out.println("Скачано успешно!");
                    playMusic(downloadedFile);
                } catch (IOException e) {
                    System.err.println("Ошибка при скачивании или обработке файла: " + e.getMessage());
                    e.printStackTrace();
                }
            }
        } catch (IOException e) {
            System.err.println("Ошибка при чтении файла или скачивании: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (musicUrlReader != null) {
                try {
                    musicUrlReader.close();
                } catch (IOException e) {
                    System.err.println("Ошибка при закрытии файла " + IN_FILE_TXT + ": " + e.getMessage());
                }
            }
        }
        System.out.println("Скачивание и прослушивание музыки завершено. Всего обработано: " + count + " файлов.");
    }
    private static void downloadUsingNIO(String urlStr, String fileFullPath) throws IOException {
        URL url = new URL(urlStr);
        HttpURLConnection httpConn = null;
        ReadableByteChannel rbc = null;
        FileOutputStream fos = null;
        try {
            httpConn = (HttpURLConnection) url.openConnection();
            httpConn.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36");
            int responseCode = httpConn.getResponseCode();
            if (responseCode == HttpURLConnection.HTTP_OK) { // HTTP_OK = 200
                rbc = Channels.newChannel(httpConn.getInputStream());
                fos = new FileOutputStream(fileFullPath);
                fos.getChannel().transferFrom(rbc, 0, Long.MAX_VALUE);
            } else {
                throw new IOException("Сервер вернул код ошибки: " + responseCode + " - " + httpConn.getResponseMessage() + " для URL: " + urlStr);
            }
        } finally {
            if (rbc != null) {
                try {
                    rbc.close();
                } catch (IOException e) {
                    System.err.println("Ошибка при закрытии ReadableByteChannel: " + e.getMessage());
                }
            }
            if (fos != null) {
                try {
                    fos.close();
                } catch (IOException e) {
                    System.err.println("Ошибка при закрытии FileOutputStream: " + e.getMessage());
                }
            }
            if (httpConn != null) {
                httpConn.disconnect(); // Важно закрыть соединение
            }
        }
    }
    private static void playMusic(File musicFile) {
        if (!musicFile.exists()) {
            System.err.println("Ошибка: Файл музыки не найден для воспроизведения: " + musicFile.getAbsolutePath());
            return;
        }
        if (Desktop.isDesktopSupported()) {
            try {
                Desktop.getDesktop().open(musicFile);
                System.out.println("Начинаю прослушивание: " + musicFile.getName());
            } catch (IOException e) {
                System.err.println("Ошибка при попытке открыть файл музыки для воспроизведения: " + musicFile.getAbsolutePath() + " - " + e.getMessage());
            } catch (UnsupportedOperationException e) {
                System.err.println("Ошибка: Открытие файлов не поддерживается на данной системе или в текущей среде Java.");
            }
        } else {
            System.err.println("Ошибка: Функция Desktop не поддерживается на данной системе. Невозможно автоматически открыть файл для прослушивания.");
        }
    }
}
