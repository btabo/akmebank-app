package org.akme.account.api;

import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.*;
import org.akme.domain.model.UserProfile;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.media.Content;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponses;
import java.util.logging.Logger;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;

@Path("/users")
public class UserProfileCommandResource {
    static final Logger logger = Logger.getLogger(UserProfileCommandResource.class.getName());

    @Inject
    public UserProfileCommandService userProfileCommandService;
    
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Request to create a user profile", description = "")
    @APIResponses(value = {
            @APIResponse(responseCode = "400", description = "Bad create user profile request", content = @Content(mediaType = "text/plain")),
            @APIResponse(responseCode = "200", description = "User profile created, return user profile unique identifier", content = @Content(mediaType = "text/plain")) })

	public Response createUserProfile(UserProfile user) {
		logger.info("createUserProfile()");
        userProfileCommandService.createUserProfile(user);
	    return Response.ok().build();
    }

    @PUT
    @Path("{Id}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Request to update a user profile", description = "")
    @APIResponses(value = {
            @APIResponse(responseCode = "400", description = "Bad update user profile request", content = @Content(mediaType = "text/plain")),
            @APIResponse(responseCode = "200", description = "User profile updated, return user profile unique identifier", content = @Content(mediaType = "text/plain")) })

	public Response updateUserProfile(@PathParam("Id") String userId, UserProfile user) {
		logger.info("updateUserProfile()");
        userProfileCommandService.updateUserProfile(user);
	    return Response.ok().build();
    }
    
    @DELETE
    @Path("{Id}")
    @Consumes(MediaType.APPLICATION_JSON)
    @Operation(summary = "Request to delete a user profile", description = "")
    @APIResponses(value = {
            @APIResponse(responseCode = "400", description = "Bad delete user profile request", content = @Content(mediaType = "text/plain")),
            @APIResponse(responseCode = "200", description = "User profile deleted, return user profile unique identifier", content = @Content(mediaType = "text/plain")) })

    public Response deleteUserProfile(@PathParam("Id") String userId) {
		logger.info("deleteUserProfile()");
        userProfileCommandService.deleteUserProfile(userId);
	    return Response.ok().build();
	}

}