/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

enum DNSServerType {
  ROOT,
  INTERMEDIATE,
  AUTHORITATIVE,
  LOCAL,

  ORIGIN, // NOT REALLY A DNS SERVER
  DESTINATION // NOT REALLY A DNS SERVER
}
