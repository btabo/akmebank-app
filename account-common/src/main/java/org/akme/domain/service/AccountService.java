package org.akme.domain.service;

import org.akme.cos.CosClient;
import org.akme.domain.model.Account;
import org.akme.utils.Config;

import java.util.ArrayList;
import java.util.List;

import com.google.gson.Gson;
import com.ibm.cloud.objectstorage.services.s3.model.S3ObjectSummary;

public class AccountService {
    private CosClient cosClient;
    private String accountBucket;

    public AccountService(){
        super();
        Config config = new Config();
        cosClient = new CosClient(
            config.getConfigValue("API_KEY"),
            config.getConfigValue("SERVICE_INSTANCE_ID"),
            config.getConfigValue("ENDPOINT_URL"),
            config.getConfigValue("LOCATION"));
        accountBucket = config.getConfigValue("ACCOUNTS_BUCKET");
    }

    public void createAccount(Account account) {
        String accountJson = new Gson().toJson(account);
        cosClient.createStringObject(accountBucket, account.getId(), accountJson);
    }

    public void deleteAccount(String accountId) {
        cosClient.deleteObject(accountBucket, accountId);
    }

    public Account getAccount(String accountId) {
        String json = cosClient.getStringObject(accountBucket, accountId);
        return new Gson().fromJson(json, Account.class);
    }

    public void updateAccount(Account account) {
        getAccount(account.getId());
        createAccount(account);
    }

    public List<Account> getAccounts() {
        List<S3ObjectSummary> objectMetaList = cosClient.listObjects(accountBucket);
        List<Account> accounts = new ArrayList<Account>();
        for (S3ObjectSummary obj : objectMetaList){
            Account account = getAccount(obj.getKey());
            accounts.add(account);
        }
        return accounts;
    }



}