package org.akme.domain.service;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import com.ibm.cloud.objectstorage.services.s3.model.S3ObjectSummary;

import org.akme.cos.CosClient;
import org.akme.cos.ObjectAccessException;
import org.akme.domain.model.Account;
import org.akme.utils.Config;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class AccountServiceTest { 
    AccountService accountService = new AccountService();
    static CosClient cosClient;

    @BeforeEach
    public void cleanUpBucket() {
        Config config = new Config();
        cosClient = new CosClient(
            config.getConfigValue("API_KEY"),
            config.getConfigValue("SERVICE_INSTANCE_ID"),
            config.getConfigValue("ENDPOINT_URL"),
            config.getConfigValue("LOCATION"));
        String accountsBucket = config.getConfigValue("ACCOUNTS_BUCKET");
        List<S3ObjectSummary> objects = cosClient.listObjects(accountsBucket);
        for (S3ObjectSummary obj : objects) {
            cosClient.deleteObject(accountsBucket, obj.getKey());
        } 
    }

    @Test
    public void createAccount()  {
        Account account = new Account("12345",Account.CHEKING_ACCOUNT, 100.00, 100.00, 0.01);
        assertDoesNotThrow( () -> accountService.createAccount(account)); 
    }

    @Test
    public void deleteAccount() {
        Account account = new Account("123456",Account.CHEKING_ACCOUNT, 100.00, 100.00, 0.01);
        accountService.createAccount(account); 
        assertDoesNotThrow( () -> accountService.deleteAccount(account.getId())); 
    }

    @Test
    public void deleteNonExistingAccount() {
        Exception exception = assertThrows(ObjectAccessException.class, () -> {
            accountService.deleteAccount("non-existent-id");
        });
        assertTrue(exception.getMessage().contains("Not Found"));
    }

    @Test
    public void getAccount() {
        Account expected = new Account("12345678",Account.CHEKING_ACCOUNT, 100.00, 100.00, 0.01);
        accountService.createAccount(expected); 
        Account actual = assertDoesNotThrow( () -> accountService.getAccount(expected.getId()));
        assertEquals(expected, actual);
    }

    @Test
    public void listAccounts() {
        for(int i=0; i<3; i++){
            Account account = new Account("123456-"+i,Account.CHEKING_ACCOUNT, 100.00, 100.00, 0.01);
            accountService.createAccount(account); 
        }
        List<Account> accounts = accountService.getAccounts();
        assertEquals(3, accounts.size());
    }

    @Test
    public void updateAccount()  {
        Account acct = new Account("12345678",Account.CHEKING_ACCOUNT, 100.00, 100.00, 0.01);
        accountService.createAccount(acct); 
        Account acctToUpdate = accountService.getAccount(acct.getId());
        acctToUpdate.setAvailableBalance(1000.00);
        acctToUpdate.setPresentBalance(1000.00);
        accountService.updateAccount(acctToUpdate);
        Account updatedAccount = accountService.getAccount(acct.getId());
        assertEquals(acctToUpdate, updatedAccount);
    }    
}