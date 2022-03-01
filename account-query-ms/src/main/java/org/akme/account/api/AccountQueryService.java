package org.akme.account.api;

import java.util.List;
import javax.enterprise.context.ApplicationScoped;
import org.akme.domain.model.Account;
import org.akme.domain.service.AccountService;

@ApplicationScoped
public class AccountQueryService {
    private AccountService accountService;

    public AccountQueryService() {
        super();
        accountService = new AccountService();
    }

    public Account getAccount(String accountId){
        return accountService.getAccount(accountId);
    }

    public List<Account> getAccounts(){
        return accountService.getAccounts();
    }

}