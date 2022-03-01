package org.akme.accounts.api;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.given;
import org.akme.domain.model.Address;
import org.akme.domain.model.UserProfile;
import org.akme.domain.service.UserProfileService;

@QuarkusTest
public class UserProfileCommandResourceTest {
    public static UserProfileService userProfileService;

    @BeforeAll
    static void initAll() {
        userProfileService = new UserProfileService();
    }

    @Test
    public void testPostUserProfile() {
        UserProfile user = makeUserProfile("u1234");
        given()
		.contentType("application/json")
		.body(user)
        .when().post("/users")
        .then()
		    .statusCode(200);
    }

    @Test
    public void testUpdateUserProfile() {
        UserProfile user = makeUserProfile("u12345");
        userProfileService.createUserProfile(user);
        user.setEmail("newemail@email.com");
        given()
        .contentType("application/json")
        .body(user)
        .when().put("/users/"+user.getId())
        .then()
		    .statusCode(200);
    }

    @Test
    public void testDeleteUserProfile() {
        UserProfile user = makeUserProfile("u123456");
        userProfileService.createUserProfile(user);
        given()
		.contentType("application/json")
        .when().delete("/users/"+user.getId())
        .then()
		    .statusCode(200);
    }

    private UserProfile makeUserProfile(String userId){
        Address address = new Address("1 Main St", "New York", "US", "NY", "10000");
        return new UserProfile(userId,"John","Doe",address,"000-000-0000","johndoe@email.com","000-00-0000",new String[] {"1234"});
    }
}