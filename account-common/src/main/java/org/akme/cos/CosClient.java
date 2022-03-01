package org.akme.cos;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.List;

import com.ibm.cloud.objectstorage.*;
import com.ibm.cloud.objectstorage.auth.*;
import com.ibm.cloud.objectstorage.oauth.*;
import com.ibm.cloud.objectstorage.services.s3.*;
import com.ibm.cloud.objectstorage.services.s3.model.*;
import com.ibm.cloud.objectstorage.client.builder.AwsClientBuilder.EndpointConfiguration;
import java.util.logging.Logger;

public class CosClient {
    private AmazonS3 cosClient;
    static final Logger logger = Logger.getLogger(CosClient.class.getName());

    /**
     * Builds a COS client
     * 
     * @param api_key
     * @param service_instance_id
     * @param endpoint_url
     * @param location
     * @return AmazonS3
     */
    public CosClient(String api_key, String service_instance_id, String endpoint_url, String location)
    {
        AWSCredentials credentials;
        credentials = new BasicIBMOAuthCredentials(api_key, service_instance_id);

        ClientConfiguration clientConfig = new ClientConfiguration().withRequestTimeout(5000);
        clientConfig.setUseTcpKeepAlive(true);

        cosClient = AmazonS3ClientBuilder.standard()
            .withCredentials(new AWSStaticCredentialsProvider(credentials))
            .withEndpointConfiguration(new EndpointConfiguration(endpoint_url, location))
            .withPathStyleAccessEnabled(true)
            .withClientConfiguration(clientConfig).build();
    }

    /**
     * 
     * Writes a text file to a bucket
     * 
     * @param bucketName
     * @param objectName
     * @param textObject
     */
    public void createStringObject(String bucketName, String objectName, String textObject) {
        InputStream newStream = new ByteArrayInputStream(textObject.getBytes(StandardCharsets.UTF_8));
    
        ObjectMetadata metadata = new ObjectMetadata();        
        metadata.setContentLength(textObject.length());
    
        PutObjectRequest req = new PutObjectRequest(bucketName, objectName, newStream, metadata);
        cosClient.putObject(req);
    }

    public String getStringObject(String bucketName, String objectName) {
        logger.info("Retrieving item from bucket: "+bucketName+", key: "+objectName);
        final int bufferSize = 1024;
        final char[] buffer = new char[bufferSize];
        final StringBuilder out = new StringBuilder();
    
        try {
            S3Object item = cosClient.getObject(new GetObjectRequest(bucketName, objectName));     
            InputStreamReader in = new InputStreamReader(item.getObjectContent());

            for (; ; ) {
                int rsz = in.read(buffer, 0, buffer.length);
                if (rsz < 0)
                    break;
                out.append(buffer, 0, rsz);
            }
        } catch (Exception e) {
            throw new ObjectAccessException("Object not found: "+objectName+" in bucket"+bucketName + " : "+e.toString());
        }
        return out.toString();
    }


    /**
     * List objects on Object Store
     * 
     * @param bucketName
     * @param cosClient
     */
    public List<S3ObjectSummary> listObjects(String bucketName) {
            ObjectListing objectListing = cosClient.listObjects(new ListObjectsRequest().withBucketName(bucketName));
            return objectListing.getObjectSummaries();
    }

    /**
     * 
     * @param bucketName
     * @param objectName
     */
    public void deleteObject(String bucketName, String objectName) {
        try {
            cosClient.getObjectMetadata(new GetObjectMetadataRequest(bucketName, objectName));
            cosClient.deleteObject(bucketName, objectName);
        } catch (Exception e) {
            throw new ObjectAccessException("Error deleting object:" + e.toString());
        }    
    }  

}        