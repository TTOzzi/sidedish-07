package com.codesquad.sidedish.api;

import com.codesquad.sidedish.entity.OAuthGithubToken;
import com.codesquad.sidedish.entity.User;
import com.codesquad.sidedish.repository.UserRepository;
import com.codesquad.sidedish.security.JwtToken;
import com.codesquad.sidedish.service.OAuthService;
import com.fasterxml.jackson.databind.JsonNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletResponse;
import javax.websocket.server.PathParam;
import java.io.IOException;

@Controller
public class LoginController {

    private static final Logger log = LoggerFactory.getLogger(SidedishController.class);

    private final OAuthService oauthService;
    private UserRepository userRepository;

    public LoginController(OAuthService oauthService, UserRepository userRepository) {
        this.oauthService = oauthService;
        this.userRepository = userRepository;
    }

    @GetMapping("/login")
    public String OauthTest(@PathParam("code") String code, HttpServletResponse response) {
        log.debug("{}", code);
        OAuthGithubToken oAuthGithubToken = oauthService.getAccessToken(code);

        log.debug("{}", oAuthGithubToken.getAuthorization());
        String accessToken = oAuthGithubToken.getAuthorization();

        ResponseEntity<JsonNode> jsonNode = oauthService.getUserEmailFromOAuthToken(accessToken);
        JsonNode body = jsonNode.getBody();

        User newUser = null;
        for (JsonNode child : body) {
            if (child.get("primary").asText().equals("true")) {
                newUser = new User(child.get("email").asText());
            }
        }
        log.debug("github user email: {}", newUser.getGithubEmail());

        if (userRepository.countByGithubEmail(newUser.getGithubEmail()) <= 0)
            userRepository.save(newUser);
      
        String jwt = JwtToken.JwtTokenMaker(newUser);
        log.debug("published token: {}", jwt);

        Cookie cookie = new Cookie("Authorization", jwt);
        cookie.setPath("/");
        response.addCookie(cookie);
        return "redirect:/";
    }
}
