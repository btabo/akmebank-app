package org.akme.account.api;

import javax.inject.Inject;
import javax.ws.rs.*;
import javax.ws.rs.core.*;
import org.akme.domain.model.UserProfile;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.media.Content;
import org.eclipse.microprofile.openapi.annotations.responses.*;
import java.util.List;
import java.util.logging.Logger;

@Path("/users")
public class UserProfileQueryResource {
    static final Logger logger = Logger.getLogger(UserProfileQueryResource.class.getName());

    @Inject
    public UserProfileQueryService userProfileQueryService;
    
    @GET
    @Path("{Id}")
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Gets a user profile by id", description = "")
    @APIResponses(value = {
            @APIResponse(responseCode = "404", description = "User profile not found", content = @Content(mediaType = "text/plain")),
            @APIResponse(responseCode = "200", description = "User profile found", content = @Content(mediaType = "application/json")) })

    public Response getUserProfileById(@PathParam("Id") String userId) {
        logger.info("getUserProfileById(" + userId + ")");
        UserProfile user = userProfileQueryService.getUserProfile(userId);
        return Response.ok().entity(user).build();
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    @Operation(summary = "Gets list of user profiles", description = "")
    @APIResponses(value = {
            @APIResponse(responseCode = "404", description = "User profiles not found", content = @Content(mediaType = "text/plain")),
            @APIResponse(responseCode = "200", description = "User profiles found", content = @Content(mediaType = "application/json")) })

    public Response getUserProfiles() {
        logger.info("getUserProfiles()");
        List<UserProfile> users = userProfileQueryService.getUserProfiles();
        return Response.ok().entity(users).build();
    }

}