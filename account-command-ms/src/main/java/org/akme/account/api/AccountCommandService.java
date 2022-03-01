package org.akme.account.api;

import javax.enterprise.context.ApplicationScoped;
import org.akme.domain.model.Account;
import org.akme.domain.service.AccountService;

@ApplicationScoped
public class AccountCommandService {
    private AccountService accountService;

    public AccountCommandService() {
        super();
        accountService = new AccountService();
    }

    public void createAccount(Account account){
        accountService.createAccount(account);
    }

    public void deleteAccount(String accountId){
        accountService.deleteAccount(accountId);
    }

    public void updateAccount(Account account){
        accountService.updateAccount(account);
    }
}