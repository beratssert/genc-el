package com.gencel.backend.security;

import com.gencel.backend.entity.User;
import com.gencel.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.lang.NonNull;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

import java.security.Principal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class WebSocketAuthChannelInterceptor implements ChannelInterceptor {

  private final JwtService jwtService;
  private final UserRepository userRepository;

  @Override
  public Message<?> preSend(@NonNull Message<?> message, @NonNull MessageChannel channel) {
    StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
    if (accessor == null || accessor.getCommand() == null) {
      return message;
    }

    StompCommand command = accessor.getCommand();
    if (StompCommand.CONNECT.equals(command)) {
      authenticate(accessor);
    } else if (StompCommand.SUBSCRIBE.equals(command)) {
      authorizeSubscription(accessor);
    }

    return message;
  }

  private void authenticate(StompHeaderAccessor accessor) {
    String token = extractBearerToken(accessor);
    if (token == null) {
      throw new IllegalArgumentException("Missing Authorization header for websocket CONNECT");
    }

    String email = jwtService.extractUsername(token);
    if (email == null || email.isBlank()) {
      throw new IllegalArgumentException("Invalid JWT for websocket CONNECT");
    }

    User user = userRepository.findByEmail(email)
        .orElseThrow(() -> new IllegalArgumentException("User not found for websocket CONNECT"));

    var principal = new UsernamePasswordAuthenticationToken(
        user.getEmail(),
        null,
        List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole().name())));
    accessor.setUser(principal);
  }

  private void authorizeSubscription(StompHeaderAccessor accessor) {
    Principal principal = accessor.getUser();
    if (principal == null) {
      authenticate(accessor);
      principal = accessor.getUser();
    }

    String email = principal != null ? principal.getName() : null;
    if (email == null || email.isBlank()) {
      throw new IllegalArgumentException("Unauthorized websocket subscription");
    }

    User user = userRepository.findByEmail(email)
        .orElseThrow(() -> new IllegalArgumentException("User not found for websocket SUBSCRIBE"));

    String destination = Optional.ofNullable(accessor.getDestination()).orElse("");

    if (destination.startsWith("/topic/users/")
        && (destination.endsWith("/tasks") || destination.endsWith("/locations"))) {
      UUID destinationUserId = parseIdFromDestination(destination, "/topic/users/");
      if (!user.getId().equals(destinationUserId)) {
        throw new IllegalArgumentException("Cannot subscribe to another user's topic");
      }
      return;
    }

    if (destination.startsWith("/topic/institutions/")
        && (destination.endsWith("/tasks") || destination.endsWith("/locations"))) {
      UUID destinationInstitutionId = parseIdFromDestination(destination, "/topic/institutions/");
      UUID userInstitutionId = user.getInstitution() != null ? user.getInstitution().getId() : null;
      if (userInstitutionId == null || !userInstitutionId.equals(destinationInstitutionId)) {
        throw new IllegalArgumentException("Cannot subscribe to another institution's topic");
      }
      return;
    }

    throw new IllegalArgumentException("Subscription destination is not allowed");
  }

  private String extractBearerToken(StompHeaderAccessor accessor) {
    List<String> authHeaders = accessor.getNativeHeader("Authorization");
    if (authHeaders == null || authHeaders.isEmpty()) {
      return null;
    }

    String auth = authHeaders.get(0);
    if (auth == null || !auth.startsWith("Bearer ")) {
      return null;
    }

    return auth.substring(7).trim();
  }

  private UUID parseIdFromDestination(String destination, String prefix) {
    String suffix;
    if (destination.endsWith("/tasks")) {
      suffix = "/tasks";
    } else if (destination.endsWith("/locations")) {
      suffix = "/locations";
    } else {
      throw new IllegalArgumentException("Unsupported destination format");
    }

    String idPart = destination.substring(prefix.length(), destination.length() - suffix.length());
    try {
      return UUID.fromString(idPart);
    } catch (IllegalArgumentException exception) {
      throw new IllegalArgumentException("Invalid destination id format");
    }
  }
}
