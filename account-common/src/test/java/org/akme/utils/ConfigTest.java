package org.akme.utils;

import static org.junit.jupiter.api.Assertions.*;

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.junit.jupiter.api.Test;



class ConfigTest {
    Config config;

    // @Test
    // public void testEnvVarInjector() throws Exception {
    //     assertNull(System.getenv("FOOBAR_ENV"));
    //     EnvVarInjector.injectEnvironmentVariable("FOOBAR_ENV", "Foo");
    //     assertEquals(System.getenv("FOOBAR_ENV"),"Foo");
    //     EnvVarInjector.removeEnvironmentVariable("FOOBAR_ENV");
    //     assertNull(System.getenv("FOOBAR_ENV"));
    // }

    @Test
    public void checkUsesMountPath() throws Exception {
        EnvVarInjector.injectEnvironmentVariable("CONFIG_MOUNT_PATH", "/tmp");
        config = new Config();
        assertTrue(config.checkUseMountPath());
        EnvVarInjector.removeEnvironmentVariable("CONFIG_MOUNT_PATH");
    }

    // @Test
    // public void getConfigValueForEnvKey() throws Exception {
    //     EnvVarInjector.injectEnvironmentVariable("ENV_KEY","ENV_VALUE");
    //     config = new Config();
    //     String value = config.getConfigValue("ENV_KEY");
    //     assertEquals("ENV_VALUE",value);
    // }

    @Test
    public void getConfigValueForMountedPathKey() throws Exception {
        EnvVarInjector.injectEnvironmentVariable("CONFIG_MOUNT_PATH", "/tmp");
        config = new Config();
        writeTestKey("MOUNTED_KEY","HELLO_MOUNTED_KEY");
        String value = config.getConfigValue("MOUNTED_KEY");
        assertEquals("HELLO_MOUNTED_KEY",value);
        EnvVarInjector.removeEnvironmentVariable("CONFIG_MOUNT_PATH");
    }

    @Test
    public void getConfigValueForNotFoundEnvKey() {
        config = new Config();
        Exception exception = assertThrows(ConfigException.class, () -> {
            config.getConfigValue("NOT_EXISTING_VALUE");
        });
        assertTrue(exception.getMessage().contains("key not found"));
    }

    @Test
    public void getConfigValueForNotFoundMountedKey() throws Exception {
        EnvVarInjector.injectEnvironmentVariable("CONFIG_MOUNT_PATH", "/tmp");
        config = new Config();
        Exception exception = assertThrows(ConfigException.class, () -> {
            config.getConfigValue("NOT_EXISTING_VALUE");
        });
        assertTrue(exception.getMessage().contains("key not found"));
        EnvVarInjector.removeEnvironmentVariable("CONFIG_MOUNT_PATH");
    }

    private void writeTestKey(String key, String value) {
        try {
          Path path = Paths.get(System. getenv("CONFIG_MOUNT_PATH"), key);
          FileWriter myWriter = new FileWriter(path.toString());
          myWriter.write(value);
          myWriter.close();
        } catch (IOException e) {
          e.printStackTrace();
        }
      }

}
