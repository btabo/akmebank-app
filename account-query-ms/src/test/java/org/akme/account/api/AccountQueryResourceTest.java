package org.akme.account.api;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.*;
import static io.restassured.RestAssured.given;
import org.akme.domain.model.Account;
import org.akme.domain.service.AccountService;
import static org.hamcrest.CoreMatchers.containsString;

@QuarkusTest
public class AccountQueryResourceTest {
    public static AccountService accountService;

    @BeforeAll
    static void initAll() {
        accountService = new AccountService();
    }

    @Test
    public void testGetAccount() {
        Account account = new Account("12345",Account.CHEKING_ACCOUNT, 100.00, 100.00, 0.01);
        accountService.createAccount(account); 
        given()
          .when().get("/accounts/12345")
          .then()
             .statusCode(200)
             .body(containsString("\"id\":\"12345\""));
    }

    @Test
    public void testGetAccounts() {
        for(int i=0;i<3;i++){
            Account account = new Account("12345-"+i,Account.CHEKING_ACCOUNT, 100.00, 100.00, 0.01);
            accountService.createAccount(account);
        }
        given()
          .when().get("/accounts")
          .then()
             .statusCode(200)
             .body(containsString("\"id\":\"12345-0\""))
             .body(containsString("\"id\":\"12345-1\""))
             .body(containsString("\"id\":\"12345-2\""));
    }

}