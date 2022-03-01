package org.akme.accounts.api;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import static io.restassured.RestAssured.given;
import org.akme.domain.model.Account;
import org.akme.domain.service.AccountService;

@QuarkusTest
public class AccountCommandResourceTest {
    public static AccountService accountService;

    @BeforeAll
    static void initAll() {
        accountService = new AccountService();
    }



    @Test
    public void testPostAccount() {
        Account account = new Account("123456789101112",Account.CHEKING_ACCOUNT, 100.00, 100.00, 0.01);
        given()
		.contentType("application/json")
		.body(account)
        .when().post("/accounts")
        .then()
		    .statusCode(200);
    }

    @Test
    public void testUpdateAccount() {
        Account account = new Account("123456789101112",Account.CHEKING_ACCOUNT, 100.00, 100.00, 0.01);
        accountService.createAccount(account);
        account.setAvailableBalance(1000.00);
        account.setPresentBalance(1000.00);
        given()
        .contentType("application/json")
        .body(account)
        .when().put("/accounts/"+account.getId())
        .then()
		    .statusCode(200);
    }

    @Test
    public void testDeleteAccount() {
        Account account = new Account("123456789101112",Account.CHEKING_ACCOUNT, 100.00, 100.00, 0.01);
        accountService.createAccount(account);
        given()
		.contentType("application/json")
        .when().delete("/accounts/"+account.getId())
        .then()
		    .statusCode(200);
    }
}