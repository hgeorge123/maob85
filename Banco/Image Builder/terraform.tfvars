cost_center   = "CC-CGS"
channel       = "SLZ"
cia           = "AAA"
product       = "Shared PRO"
app_name      = "glbsha"
tracking_code = "GLBSHA"
region        = "us-east-1"
account_id    = "754151944497"
role_name     = "AccountAutomationPro"
entity        = "cgs"
environment   = "p2"
shared_costs  = "yes"

#############################################################################################################
#COMMON
vpc_id          = "vpc-0734f56ef4a32d40f"
subnet_id = "subnet-044ac5c3fad856313"
mandatory_tags  = {
  cost_center   = "CC-CGS"
  channel       = "SLZ"
  cia           = "AAA"
  product       = "Shared PRO"
  Description   = "Image Builder"
  app_name      = "glbsha"
  tracking_code = "GLBSHA"
  region        = "us-east-1"
  account_id    = "754151944497"
  role_name     = "AccountAutomationPro"
  entity        = "cgs"
  environment   = "p2"
  shared_costs  = "yes"
  apm_functional = "ImageBuilder"
  tfstate_tag   = "santander-group-scfccoe"
}

custom_tags = {
  "custom_tag_key" = "custom_tag_value"
}
security_group_ids = null

#IMAGE BUILDER

image_builder_config =  {
   "rhel8" ={
        image_builder_ami = "ami-0fd3ac4abb734302a"
        image_builder_ami_name_tag	= "CCoE_SCF_RHEL8"
        image_builder_ebs_root_vol_size = 130
        image_builder_image_recipe_version = "1.0.0"
        image_builder_instance_types = ["t3a.xlarge"]
        component_names = []
        custom_components = [
        {
          "name":"update-os-redhat8",
          "description":"Update OS Redhat",
          "filename":"update-os-redhat89.yml"
        }
      ]
        email_notifications = ["maob85@gmail.com"]
    },
   "windows2019" = {
	    image_builder_ami= "ami-054aa34c67d3092b3"
	    image_builder_ami_name_tag	= "CCoE_SCF_Win2019"
      image_builder_ebs_root_vol_size = 130
      image_builder_image_recipe_version = "1.0.3"
      image_builder_instance_types = ["t3a.xlarge"]
      component_names = []
	    custom_components = [
	 	  # {
	 		#     "name":"windows-wsus",
	 		#     "description":"Windows SUS",
	 		#     "filename":"windows-wsus.yml"
	 	  # },
	 	  {
	 		     "name":"user-winrm",
	 		     "description":"Create WinRM",
	 		     "filename":"windows-winrm.yml"
	 	  },
	 	  # {
	 		#      "name":"update-windows",
	 		#      "description":"Update Windows",
	 		#      "filename":"update-windows.yml"
	 	  # },
	 	  {
	 		     "name":"reboot-windows",
	 		     "description":"Reboot Windows",
	 		     "filename":"reboot-windows.yml"
	 	  }
	   ]
       email_notifications = ["maob85@gmail.com"]
     },
  #   "rhel9" ={
  #       image_builder_ami = "ami-08a02e036c2b72d18"
  #       image_builder_ami_name_tag	= "CCoE_SCF_RHEL9"
  #       image_builder_ebs_root_vol_size = 130
  #       image_builder_image_recipe_version = "1.0.0"
  #       image_builder_instance_types = ["t3a.xlarge"]
  #       component_names = []
  #       custom_components = [
  #       {
  #         "name":"update-os-redhat9",
  #         "description":"Update OS Redhat",
  #         "filename":"update-os-redhat9.yml"
  #       }
  #     ]
  #       email_notifications = ["maob85@gmail.com"]
  #     },
  #  "windows2022" = {
	#     image_builder_ami= "ami-047c7d0e7fb394c06"
	#     image_builder_ami_name_tag	= "CCoE_SCF_Win2022"
  #     image_builder_ebs_root_vol_size = 130
  #     image_builder_image_recipe_version = "1.0.7"
  #     image_builder_instance_types = ["t3a.xlarge"]
  #     component_names = []
	#     custom_components = [
	#  	  {
	#  		    "name":"windows-wsus2022",
	#  		    "description":"Windows SUS",
	#  		    "filename":"windows-wsus-2022.yml"
	#  	  },
	#  	  {
	#  		     "name":"user-winrm2022",
	#  		     "description":"Create WinRM",
	#  		     "filename":"windows-winrm-2022.yml"
	#  	  },
	#  	  {
	#  		     "name":"update-windows2022",
	#  		     "description":"Update Windows",
	#  		     "filename":"update-windows-2022.yml"
	#  	  },
	#  	  {
	#  		     "name":"reboot-windows2022",
	#  		     "description":"Reboot Windows",
	#  		     "filename":"reboot-windows-2022.yml"
	#  	  }
	#    ]
  #      email_notifications = ["maob85@gmail.com"]
  #    },
  }