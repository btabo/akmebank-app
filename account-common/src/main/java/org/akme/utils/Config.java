package org.akme.utils;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class Config{
    private static String configMountPath;

    public Config(){
        configMountPath = System. getenv("CONFIG_MOUNT_PATH");
    }

    public String getConfigValue(String configKey) {
        String configValue = getConfigValueFromEnvOrFromMount(configKey);
        if (configValue == null){
            throw new ConfigException("key not found: "+configKey);
        }
        return configValue;
    }

    private String getConfigValueFromEnvOrFromMount(String configKey) {
        if (checkUseMountPath()) {
            try {
                return getValueFromMountPath(configKey);
            }catch (Exception e) {
                throw new ConfigException(e.getMessage());
            }
        } else {
            return System. getenv(configKey);
        }
    }

    public boolean checkUseMountPath() {
        return (configMountPath != null);
    }

    private String getValueFromMountPath(String configKey) throws FileNotFoundException, IOException{
        Path filePath = Paths.get(configMountPath, configKey);
        File f  = filePath.toFile();
        if (!f.exists()) {
            throw new FileNotFoundException("key not found: "+configKey);
        }
        String content = "";
        content = new String (Files.readAllBytes(filePath));
        return content;
    }


}