// Copyright (C) 2015 The Android Open Source Project
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.googlesource.gerrit.plugins.lfs.remote;

import com.google.common.base.Strings;
import com.google.inject.Inject;
import com.google.inject.assistedinject.Assisted;
import com.googlesource.gerrit.plugins.lfs.LfsBackend;
import com.googlesource.gerrit.plugins.lfs.LfsConfigurationFactory;
import com.googlesource.gerrit.plugins.lfs.LfsGlobalConfig;
import java.net.URI;
import org.eclipse.jgit.lfs.server.LargeFileRepository;
import org.eclipse.jgit.lfs.server.Response;
import org.eclipse.jgit.lfs.lib.AnyLongObjectId;

/**
 * Repository implementation that proxies requests to a remote LFS server.
 *
 * <p>This implementation forwards LFS operations to a remote LFS server specified by a URL.
 * The remote server must implement the Git LFS Batch API. Supports both HTTP/HTTPS and SSH URLs.
 */
public class RemoteLargeFileRepository implements LargeFileRepository {
  public interface Factory {
    RemoteLargeFileRepository create(LfsBackend backendConfig);
  }

  private final URI remoteUrl;
  private final String username;
  private final String password;
  private final boolean disableSslVerify;
  private final boolean isSsh;
  private final String sshHost;
  private final int sshPort;
  private final String sshUser;
  private final String sshKeyFile;
  private final String sshKeyPassphrase;

  @Inject
  RemoteLargeFileRepository(
      LfsConfigurationFactory configFactory, @Assisted LfsBackend backendConfig) {
    LfsGlobalConfig config = configFactory.getGlobalConfig();
    String section = backendConfig.type.name();

    String url = config.getString(section, backendConfig.name, "url");
    String sshHostConfig = config.getString(section, backendConfig.name, "sshHost");
    String sshUserConfig = config.getString(section, backendConfig.name, "sshUser");
    String sshKeyFileConfig = config.getString(section, backendConfig.name, "sshKeyFile");
    int sshPortConfig = config.getInt(section, backendConfig.name, "sshPort", 22);

    // Determine if using SSH
    boolean useSsh = false;
    if (!Strings.isNullOrEmpty(url) && url.startsWith("ssh://")) {
      useSsh = true;
    } else if (!Strings.isNullOrEmpty(sshHostConfig)) {
      useSsh = true;
    }

    this.isSsh = useSsh;

    if (useSsh) {
      // SSH configuration
      if (!Strings.isNullOrEmpty(sshHostConfig)) {
        this.sshHost = sshHostConfig;
        this.sshPort = sshPortConfig;
        this.sshUser = sshUserConfig;
        this.sshKeyFile = sshKeyFileConfig;
        this.sshKeyPassphrase = config.getString(section, backendConfig.name, "sshKeyPassphrase");
        // For SSH, construct URL from components if not provided
        if (Strings.isNullOrEmpty(url)) {
          String userPart = Strings.isNullOrEmpty(sshUser) ? "" : sshUser + "@";
          url = "ssh://" + userPart + sshHost + ":" + sshPort;
        }
      } else if (!Strings.isNullOrEmpty(url) && url.startsWith("ssh://")) {
        // Parse SSH URL: ssh://[user@]host[:port][/path]
        try {
          URI sshUri = new URI(url);
          this.sshHost = sshUri.getHost();
          this.sshPort = sshUri.getPort() > 0 ? sshUri.getPort() : 22;
          String userInfo = sshUri.getUserInfo();
          this.sshUser = Strings.isNullOrEmpty(userInfo) ? null : userInfo;
          this.sshKeyFile = sshKeyFileConfig;
          this.sshKeyPassphrase = config.getString(section, backendConfig.name, "sshKeyPassphrase");
        } catch (java.net.URISyntaxException e) {
          throw new IllegalArgumentException(
              String.format(
                  "Remote backend '%s' has invalid SSH 'url' configuration: %s",
                  backendConfig.name(), e.getMessage()),
              e);
        }
      } else {
        throw new IllegalArgumentException(
            String.format(
                "Remote backend '%s' requires either 'url' starting with 'ssh://' or 'sshHost' configuration",
                backendConfig.name()));
      }

      // For SSH, we still create a URI for consistency, but it represents the SSH connection
      try {
        this.remoteUrl = new URI(url);
      } catch (java.net.URISyntaxException e) {
        throw new IllegalArgumentException(
            String.format(
                "Remote backend '%s' has invalid 'url' configuration: %s",
                backendConfig.name(), e.getMessage()),
            e);
      }
      this.username = null;
      this.password = null;
      this.disableSslVerify = false;
    } else {
      // HTTP/HTTPS configuration
      if (Strings.isNullOrEmpty(url)) {
        throw new IllegalArgumentException(
            String.format("Remote backend '%s' requires 'url' configuration", backendConfig.name()));
      }

      // Normalize the base URL - remove trailing slashes
      String baseUrl = url.trim().replaceAll("/+$", "");
      if (baseUrl.isEmpty()) {
        throw new IllegalArgumentException(
            String.format(
                "Remote backend '%s' has invalid 'url' configuration", backendConfig.name()));
      }

      try {
        this.remoteUrl = new URI(baseUrl);
      } catch (java.net.URISyntaxException e) {
        throw new IllegalArgumentException(
            String.format(
                "Remote backend '%s' has invalid 'url' configuration: %s",
                backendConfig.name(), e.getMessage()),
            e);
      }
      this.username = config.getString(section, backendConfig.name, "username");
      this.password = config.getString(section, backendConfig.name, "password");
      this.disableSslVerify =
          config.getBoolean(section, backendConfig.name, "disableSslVerify", false);
      this.sshHost = null;
      this.sshPort = 22;
      this.sshUser = null;
      this.sshKeyFile = null;
      this.sshKeyPassphrase = null;
    }
  }

  @Override
  public Response.Action getDownloadAction(AnyLongObjectId id) {
    // Return action pointing to remote LFS server
    // The href will be constructed by the LFS protocol handler based on the remote URL
    String downloadUrl = buildObjectUrl(id);
    Response.Action action = new Response.Action();
    action.href = downloadUrl;
    return action;
  }

  @Override
  public Response.Action getUploadAction(AnyLongObjectId id, long size) {
    // Return action pointing to remote LFS server
    String uploadUrl = buildObjectUrl(id);
    Response.Action action = new Response.Action();
    action.href = uploadUrl;
    return action;
  }

  @Override
  public Response.Action getVerifyAction(AnyLongObjectId id) {
    // Return action pointing to remote LFS server for verification
    // Verification checks if the object exists on the remote server
    String verifyUrl = buildObjectUrl(id);
    Response.Action action = new Response.Action();
    action.href = verifyUrl;
    return action;
  }

  @Override
  public long getSize(AnyLongObjectId id) {
    // For remote storage, we cannot determine the size without querying the remote server
    // Return -1 to indicate size is unknown (the remote server will handle size validation)
    return -1;
  }

  private String buildObjectUrl(AnyLongObjectId id) {
    if (isSsh) {
      // For SSH, build SFTP-style path: ssh://user@host:port/path/to/objects/oid
      // or use the path from the original URL if provided
      String baseUrl = remoteUrl.toString();
      String path = remoteUrl.getPath();
      if (Strings.isNullOrEmpty(path) || path.equals("/")) {
        path = "/objects/" + id.getName();
      } else {
        if (!path.endsWith("/")) {
          path += "/";
        }
        path += "objects/" + id.getName();
      }
      // Reconstruct SSH URL with path
      String userInfo = remoteUrl.getUserInfo();
      String userPart = Strings.isNullOrEmpty(userInfo) ? "" : userInfo + "@";
      int port = remoteUrl.getPort();
      String portPart = (port > 0 && port != 22) ? ":" + port : "";
      return "ssh://" + userPart + remoteUrl.getHost() + portPart + path;
    } else {
      // Build URL to the remote LFS server's object endpoint
      // The remote server should handle the actual object storage
      // Format: <base-url>/objects/<oid>
      String baseUrl = remoteUrl.toString();
      if (!baseUrl.endsWith("/")) {
        baseUrl += "/";
      }
      return baseUrl + "objects/" + id.getName();
    }
  }

  public URI getRemoteUrl() {
    return remoteUrl;
  }

  public String getUsername() {
    return username;
  }

  public String getPassword() {
    return password;
  }

  public boolean isDisableSslVerify() {
    return disableSslVerify;
  }

  public boolean isSsh() {
    return isSsh;
  }

  public String getSshHost() {
    return sshHost;
  }

  public int getSshPort() {
    return sshPort;
  }

  public String getSshUser() {
    return sshUser;
  }

  public String getSshKeyFile() {
    return sshKeyFile;
  }

  public String getSshKeyPassphrase() {
    return sshKeyPassphrase;
  }
}

