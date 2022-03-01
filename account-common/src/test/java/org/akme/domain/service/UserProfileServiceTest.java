package org.akme.domain.service;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import com.ibm.cloud.objectstorage.services.s3.model.S3ObjectSummary;

import org.akme.cos.CosClient;
import org.akme.cos.ObjectAccessException;
import org.akme.domain.model.Address;
import org.akme.domain.model.UserProfile;
import org.akme.utils.Config;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class UserProfileServiceTest { 
    UserProfileService userProfileService = new UserProfileService();

    static CosClient cosClient;


    @BeforeEach
    public void cleanUpBucket() {
        Config config = new Config();
        cosClient = new CosClient(
            config.getConfigValue("API_KEY"),
            config.getConfigValue("SERVICE_INSTANCE_ID"),
            config.getConfigValue("ENDPOINT_URL"),
            config.getConfigValue("LOCATION"));
        String usersBucket = config.getConfigValue("USERS_BUCKET");
        List<S3ObjectSummary> objects = cosClient.listObjects(usersBucket);
        for (S3ObjectSummary obj : objects) {
            cosClient.deleteObject(usersBucket, obj.getKey());
        } 
    }

    @Test
    public void createUserProfile()  {
        UserProfile userProfile = makeUserProfile("u1234");
        assertDoesNotThrow( () -> userProfileService.createUserProfile(userProfile)); 
    }

    @Test
    public void deleteUserProfile() {
        UserProfile userProfile = makeUserProfile("u1234");
        userProfileService.createUserProfile(userProfile); 
        assertDoesNotThrow( () -> userProfileService.deleteUserProfile(userProfile.getId())); 
    }

    @Test
    public void deleteNonExistingUserProfile() {
        Exception exception = assertThrows(ObjectAccessException.class, () -> {
            userProfileService.deleteUserProfile("non-existent-id");
        });
        assertTrue(exception.getMessage().contains("Not Found"));
    }

    @Test
    public void getUserProfile() {
        UserProfile expected = makeUserProfile("u1234");
        userProfileService.createUserProfile(expected); 
        UserProfile actual = assertDoesNotThrow( () -> userProfileService.getUserProfile(expected.getId()));
        assertEquals(expected, actual);
    }

    @Test
    public void listUserProfiles() {
        for(int i=0; i<3; i++){
            UserProfile userProfile = makeUserProfile("u123"+i);
            userProfileService.createUserProfile(userProfile); 
        }
        List<UserProfile> userProfiles = userProfileService.getUserProfiles();
        assertEquals(3, userProfiles.size());
    }

    @Test
    public void updateUserProfile()  {
        UserProfile user = makeUserProfile("u1234");
        userProfileService.createUserProfile(user); 
        UserProfile userToUpdate = userProfileService.getUserProfile(user.getId());
        userToUpdate.setPhoneNumber("111-111-1111");
        userProfileService.updateUserProfile(userToUpdate);
        UserProfile updatedUser = userProfileService.getUserProfile(user.getId());
        assertEquals(userToUpdate, updatedUser);
    } 

    private UserProfile makeUserProfile(String userId){
        Address address = new Address("1 Main St", "New York", "US", "NY", "10000");
        return new UserProfile(userId,"John","Doe",address,"000-000-0000","johndoe@email.com","000-00-0000",new String[] {"1234"});
    }

}