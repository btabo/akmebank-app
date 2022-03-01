package org.akme.account.api;


import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.*;

import org.akme.domain.model.Account;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.media.Content;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponses;
import java.util.logging.Logger;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;

@Path("/accounts")
public class AccountCommandResource {
    static final Logger logger = Logger.getLogger(AccountCommandResource.class.getName());

    @Inject
    public AccountCommandService accountCommandService;
    
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Request to create an account", description = "")
    @APIResponses(value = {
            @APIResponse(responseCode = "400", description = "Bad create account request", content = @Content(mediaType = "text/plain")),
            @APIResponse(responseCode = "200", description = "Account created, return account unique identifier", content = @Content(mediaType = "text/plain")) })

	public Response createAccount(Account account) {
		logger.info("createAccount()");
        accountCommandService.createAccount(account);
	    return Response.ok().build();
    }

    @PUT
    @Path("{Id}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Request to update an account", description = "")
    @APIResponses(value = {
            @APIResponse(responseCode = "400", description = "Bad update account request", content = @Content(mediaType = "text/plain")),
            @APIResponse(responseCode = "200", description = "Account updated, return account unique identifier", content = @Content(mediaType = "text/plain")) })

	public Response updateAccount(@PathParam("Id") String accountId, Account account) {
		logger.info("updateAccount()");
        accountCommandService.updateAccount(account);
	    return Response.ok().build();
    }
    
    @DELETE
    @Path("{Id}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Operation(summary = "Request to delete an account", description = "")
    @APIResponses(value = {
            @APIResponse(responseCode = "400", description = "Bad delete account request", content = @Content(mediaType = "text/plain")),
            @APIResponse(responseCode = "200", description = "Account deleted, return account unique identifier", content = @Content(mediaType = "text/plain")) })

    public Response deleteAccount(@PathParam("Id") String accountId) {
		logger.info("deleteAccount()");
        accountCommandService.deleteAccount(accountId);
	    return Response.ok().build();
	}

}