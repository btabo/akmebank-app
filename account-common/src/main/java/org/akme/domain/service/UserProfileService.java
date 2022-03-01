package org.akme.domain.service;

import org.akme.cos.CosClient;
import org.akme.domain.model.UserProfile;
import org.akme.utils.Config;

import java.util.ArrayList;
import java.util.List;
import com.google.gson.Gson;
import com.ibm.cloud.objectstorage.services.s3.model.S3ObjectSummary;

public class UserProfileService {
    private CosClient cosClient;
    private String usersBucket;

    public UserProfileService(){
        super();
        Config config = new Config();
        cosClient = new CosClient(
            config.getConfigValue("API_KEY"),
            config.getConfigValue("SERVICE_INSTANCE_ID"),
            config.getConfigValue("ENDPOINT_URL"),
            config.getConfigValue("LOCATION"));
        usersBucket = config.getConfigValue("USERS_BUCKET");
    }

    public void createUserProfile(UserProfile userProfile) {
        String userProfileJson = new Gson().toJson(userProfile);
        cosClient.createStringObject(usersBucket, userProfile.getId(), userProfileJson);
    }

    public void updateUserProfile(UserProfile userProfile) {
        getUserProfile(userProfile.getId());
        createUserProfile(userProfile);
    }

    public void deleteUserProfile(String userId) {
        cosClient.deleteObject(usersBucket, userId);
    }

    public UserProfile getUserProfile(String userId) {
        String json = cosClient.getStringObject(usersBucket, userId);
        return new Gson().fromJson(json, UserProfile.class);
    }

    public List<UserProfile> getUserProfiles() {
        List<S3ObjectSummary> objectMetaList = cosClient.listObjects(usersBucket);
        List<UserProfile> userProfiles = new ArrayList<UserProfile>();
        for (S3ObjectSummary obj : objectMetaList){
            UserProfile userProfile = getUserProfile(obj.getKey());
            userProfiles.add(userProfile);
        }
        return userProfiles;
    }
}