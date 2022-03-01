package org.akme.account.api;

import javax.enterprise.context.ApplicationScoped;
import org.akme.domain.model.UserProfile;
import org.akme.domain.service.UserProfileService;

@ApplicationScoped
public class UserProfileCommandService {
    private UserProfileService userProfileService;

    public UserProfileCommandService() {
        super();
        userProfileService = new UserProfileService();
    }

    public void createUserProfile(UserProfile user){
        userProfileService.createUserProfile(user);
    }

    public void deleteUserProfile(String userId){
        userProfileService.deleteUserProfile(userId);
    }

    public void updateUserProfile(UserProfile user){
        userProfileService.updateUserProfile(user);
    }
}