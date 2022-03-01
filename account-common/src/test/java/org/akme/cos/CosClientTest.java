package org.akme.cos;

import static org.junit.jupiter.api.Assertions.*;
import java.util.List;
import org.akme.utils.Config;
import org.junit.jupiter.api.*;
import com.ibm.cloud.objectstorage.services.s3.model.*;


class CosClientTest {
    static CosClient cosClient;
    static String testBucket;

    @BeforeAll
    static void initAll() {
        Config config = new Config();
        cosClient = new CosClient(
            config.getConfigValue("API_KEY"),
            config.getConfigValue("SERVICE_INSTANCE_ID"),
            config.getConfigValue("ENDPOINT_URL"),
            config.getConfigValue("LOCATION"));

        testBucket = config.getConfigValue("TEST_BUCKET");
        List<S3ObjectSummary> objects = cosClient.listObjects(testBucket);
        for (S3ObjectSummary obj : objects) {
            cosClient.deleteObject(testBucket, obj.getKey());
        } 
    }

    @Test
    public void testWriteStringObject() {
        String expected = "hello this is a test string"; 
        String key = "key";
        assertDoesNotThrow( () -> cosClient.createStringObject(testBucket, key, expected)); 
        String actual = assertDoesNotThrow( () -> cosClient.getStringObject(testBucket, key));
        assertEquals(expected, actual);
        cosClient.deleteObject(testBucket, key);
    }

    @Test
    public void testUpdateStringObject() {
        String val = "hello this is a test string"; 
        String key = "keyupd";
        assertDoesNotThrow( () -> cosClient.createStringObject(testBucket, key, val)); 
        String updval = "hello this is an update test string";
        assertDoesNotThrow( () -> cosClient.createStringObject(testBucket, key, updval)); 
        String actual = assertDoesNotThrow( () -> cosClient.getStringObject(testBucket, key));
        assertEquals(updval, actual);
        cosClient.deleteObject(testBucket, key);
    }

    @Test
    public void testListObjects(){
        for (int i=0;i<3;i++){
            cosClient.createStringObject(testBucket, "key"+i, "value"+i);
        }
        List<S3ObjectSummary> objects = cosClient.listObjects(testBucket);
        assertEquals(objects.size(),3);
        for (int i=0;i<3;i++){
            cosClient.deleteObject(testBucket, "key"+i);
        }
    }

    @Test
    public void testDeleteObject(){
        String key = "key";
        String value = "value";
        cosClient.createStringObject(testBucket, key, value);
        cosClient.deleteObject(testBucket, key);
        Exception exception = assertThrows(ObjectAccessException.class, () -> {
            cosClient.getStringObject(testBucket, key);
        });
        assertTrue(exception.getMessage().contains("Object not found"));
    }

    @Test
    public void testDeleteNonExistingObject(){
        Exception exception = assertThrows(ObjectAccessException.class, () -> {
            cosClient.deleteObject(testBucket, "non-existing-object-key");
        });
        assertTrue(exception.getMessage().contains("Not Found"));
    }
}
