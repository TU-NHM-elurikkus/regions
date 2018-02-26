class UrlMappings {

	static mappings = {

        "/logout/logout" (controller: "logout", action: "logout")

        "/feature/$pid" (controller: "regions", action: "region")

        name regionByFeature: "/feature/$pid" (controller: "regions", action: "region")

        "/$regionType/$regionName" (controller: "regions", action: "region") {
            constraints {
                //do not match controllers
                regionType(matches:"(?!(^data\$|^proxy\$|^region\$|^regions\$)).*")
            }
        }

        "/$regionType" (controller: "regions", action: "regions") {
            constraints {
                //do not match controllers
                regionType(matches:"(?!(^data\$|^proxy\$|^region\$|^regions\$)).*")
            }
        }

        "/clear-cache" (controller: "regions", action: "clearCache")

		"/$controller/$action?/$id?(.$format)?" {
			constraints {
				// apply constraints here
			}
		}

		"/"(controller: "regions")
		"500"(view: "/error")
	}
}
