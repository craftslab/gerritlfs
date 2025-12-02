// Copyright (C) 2016 The Android Open Source Project
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

package com.googlesource.gerrit.plugins.lfs;

import com.google.common.base.Strings;
import com.google.common.flogger.FluentLogger;
import com.google.gerrit.entities.Project;
import com.google.inject.Inject;
import java.util.Map;
import org.eclipse.jgit.lfs.errors.LfsRepositoryNotFound;
import org.eclipse.jgit.lfs.server.LargeFileRepository;

public class LfsRepositoryResolver {
  private static final FluentLogger log = FluentLogger.forEnclosingClass();

  private final LfsRepositoriesCache cache;
  private final LfsBackend defaultBackend;
  private final Map<String, LfsBackend> backends;
  private final LfsConfigurationFactory configFactory;

  @Inject
  LfsRepositoryResolver(LfsRepositoriesCache cache, LfsConfigurationFactory configFactory) {
    this.cache = cache;
    this.configFactory = configFactory;

    LfsGlobalConfig config = configFactory.getGlobalConfig();
    this.defaultBackend = config.getDefaultBackend();
    this.backends = config.getBackends();
  }

  public LargeFileRepository get(Project.NameKey project, String backendName)
      throws LfsRepositoryNotFound {
    LfsBackend backend;
    if (Strings.isNullOrEmpty(backendName)) {
      backend = defaultBackend;
    } else {
      // Support remote:http and remote:ssh syntax for explicit protocol selection
      if (backendName.startsWith("remote:")) {
        String protocol = backendName.substring("remote:".length()).toLowerCase();
        String targetBackend = null;

        if ("http".equals(protocol) || "https".equals(protocol)) {
          // Look for http-backend or https-backend
          targetBackend = findRemoteBackend("http");
        } else if ("ssh".equals(protocol)) {
          // Look for ssh-backend
          targetBackend = findRemoteBackend("ssh");
        }

        if (targetBackend != null) {
          backend = backends.get(targetBackend);
        } else {
          log.atSevere().log(
              "Project %s requested remote:%s backend but no matching backend found",
              project, protocol);
          throw new LfsRepositoryNotFound(project.get());
        }
      } else if ("remote".equals(backendName)) {
        // Automatic selection: find available remote backends
        String httpBackend = findRemoteBackend("http");
        String sshBackend = findRemoteBackend("ssh");

        if (httpBackend != null && sshBackend != null) {
          // Both exist: prefer HTTP by default, but can be overridden via config
          // For now, default to HTTP
          backend = backends.get(httpBackend);
          log.atFine().log(
              "Project %s using 'remote' backend: auto-selected %s (http-backend available, ssh-backend also available)",
              project, httpBackend);
        } else if (httpBackend != null) {
          backend = backends.get(httpBackend);
          log.atFine().log(
              "Project %s using 'remote' backend: auto-selected %s (http-backend)",
              project, httpBackend);
        } else if (sshBackend != null) {
          backend = backends.get(sshBackend);
          log.atFine().log(
              "Project %s using 'remote' backend: auto-selected %s (ssh-backend)",
              project, sshBackend);
        } else {
          // No remote backends found, check if default is REMOTE
          if (defaultBackend.type == LfsBackendType.REMOTE) {
            backend = defaultBackend;
          } else {
            log.atSevere().log(
                "Project %s configured with 'remote' backend but no remote backends found",
                project);
            throw new LfsRepositoryNotFound(project.get());
          }
        }
      } else {
        backend = backends.get(backendName);
        if (backend == null) {
          log.atSevere().log(
              "Project %s is configured with not existing backend %s", project, backendName);
          throw new LfsRepositoryNotFound(project.get());
        }
      }
    }

    LargeFileRepository repository = cache.get(backend);
    if (repository != null) {
      return repository;
    }

    // this is unlikely situation as cache is pre-populated from config but...
    log.atSevere().log(
        "Project %s is configured with not existing backend %s of type %s",
        project, backend.name(), backend.type);
    throw new LfsRepositoryNotFound(project.get());
  }

  /**
   * Find a remote backend that matches the protocol type (http or ssh).
   * Checks both the backend name and actual configuration.
   *
   * @param protocol "http" or "ssh"
   * @return backend name if found, null otherwise
   */
  private String findRemoteBackend(String protocol) {
    LfsGlobalConfig config = configFactory.getGlobalConfig();

    for (Map.Entry<String, LfsBackend> entry : backends.entrySet()) {
      if (entry.getValue().type == LfsBackendType.REMOTE) {
        String name = entry.getKey();
        LfsBackend backend = entry.getValue();

        // Check actual configuration to determine protocol
        String url = config.getString("REMOTE", backend.name, "url");
        String sshHost = config.getString("REMOTE", backend.name, "sshHost");

        boolean isSsh = false;
        if (!Strings.isNullOrEmpty(url) && url.startsWith("ssh://")) {
          isSsh = true;
        } else if (!Strings.isNullOrEmpty(sshHost)) {
          isSsh = true;
        }

        // Also check name as fallback
        String lowerName = name.toLowerCase();
        if (protocol.equals("http") && !isSsh && (lowerName.contains("http") || lowerName.contains("https") || Strings.isNullOrEmpty(sshHost))) {
          return name;
        } else if (protocol.equals("ssh") && (isSsh || lowerName.contains("ssh"))) {
          return name;
        } else if (protocol.equals("http") && !isSsh) {
          // If it's not SSH and we're looking for HTTP, it's a match
          return name;
        }
      }
    }
    return null;
  }
}
