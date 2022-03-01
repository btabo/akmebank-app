package org.akme.account.api;

import java.util.List;
import javax.enterprise.context.ApplicationScoped;
import org.akme.domain.model.UserProfile;
import org.akme.domain.service.UserProfileService;

@ApplicationScoped
public class UserProfileQueryService {
    private UserProfileService userProfileService;

    public UserProfileQueryService() {
        super();
        userProfileService = new UserProfileService();
    }

    public UserProfile getUserProfile(String userId){
        return userProfileService.getUserProfile(userId);
    }

    public List<UserProfile> getUserProfiles(){
        return userProfileService.getUserProfiles();
    }

}