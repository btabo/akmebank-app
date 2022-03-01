package org.akme.account.api;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.*;
import static io.restassured.RestAssured.given;
import org.akme.domain.model.Address;
import org.akme.domain.model.UserProfile;
import org.akme.domain.service.UserProfileService;
import static org.hamcrest.CoreMatchers.containsString;

@QuarkusTest
public class UserProfileQueryResourceTest {
    public static UserProfileService userProfileService;

    @BeforeAll
    static void initAll() {
        userProfileService = new UserProfileService();
    }

    @Test
    public void testGetUserProfile() {
        UserProfile user = makeUserProfile("u1234");
        userProfileService.createUserProfile(user); 
        given()
          .when().get("/users/u1234")
          .then()
             .statusCode(200)
             .body(containsString("\"id\":\"u1234\""));
    }

    @Test
    public void testGetUserProfiles() {
        for(int i=0;i<3;i++){
            UserProfile user = makeUserProfile("u1234-"+i);
            userProfileService.createUserProfile(user); 
        }
        given()
          .when().get("/users")
          .then()
             .statusCode(200)
             .body(containsString("\"id\":\"u1234-0\""))
             .body(containsString("\"id\":\"u1234-1\""))
             .body(containsString("\"id\":\"u1234-2\""));
    }

    private UserProfile makeUserProfile(String userId){
        Address address = new Address("1 Main St", "New York", "US", "NY", "10000");
        return new UserProfile(userId,"John","Doe",address,"000-000-0000","johndoe@email.com","000-00-0000",new String[] {"1234"});
    }
}