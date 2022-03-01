package org.akme.account.api;

import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.*;
import org.akme.domain.model.Account;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.media.Content;
import org.eclipse.microprofile.openapi.annotations.responses.*;

import java.util.List;
import java.util.logging.Logger;

@Path("/accounts")
public class AccountQueryResource {
    static final Logger logger = Logger.getLogger(AccountQueryResource.class.getName());

    @Inject
    public AccountQueryService accountQueryService;
    
    @GET
    @Path("{Id}")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Gets an account by id", description = "")
    @APIResponses(value = {
            @APIResponse(responseCode = "404", description = "Account not found", content = @Content(mediaType = "text/plain")),
            @APIResponse(responseCode = "200", description = "Account found", content = @Content(mediaType = "application/json")) })

    public Response getAccountById(@PathParam("Id") String accountId) {
        logger.info("getAccountById(" + accountId + ")");
        Account account = accountQueryService.getAccount(accountId);
        return Response.ok().entity(account).build();
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Gets accounts", description = "")
    @APIResponses(value = {
            @APIResponse(responseCode = "404", description = "Accounts not found", content = @Content(mediaType = "text/plain")),
            @APIResponse(responseCode = "200", description = "Accounts found", content = @Content(mediaType = "application/json")) })

    public Response getAccounts() {
        logger.info("getAccounts()");
        List<Account> accounts = accountQueryService.getAccounts();
        return Response.ok().entity(accounts).build();
    }

}