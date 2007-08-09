/'	FbEdit strings

	1-			Critical messages
	100-		Main window
	1000-		Find dialog / messages
	1100-		Menu options dialog
	1200-		New project dialog
	1300-		Project tab main window
	2000-		File open / save dialogs
	3000-		Messageboxes

'/

#DEFINE IS_COULD_NOT_FIND               1
#DEFINE IS_FILE                         100
#DEFINE IS_PROJECT                      101
#DEFINE IS_FIND                         1000
#DEFINE IS_NEXT                         1001
#DEFINE IS_PREVIOUS                     1002
#DEFINE IS_REPLACE                      1003
#DEFINE IS_REGION_SEARCHED              1004
#DEFINE IS_REPLACEMENTS_DONE            1005
#DEFINE IS_PROJECT_FILES_SEARCHED       1006
#DEFINE IS_REGION_SEARCHED_INFO         1007
#DEFINE IS_PROJECT_FILES_SEARCHED_INFO  1008
#DEFINE IS_TOOLS_MENU_OPTION            1100
#DEFINE IS_HELP_MENU_OPTION             1101
#DEFINE IS_BUILD_OPTIONS                1102
#DEFINE IS_PROJECT_BUILD_OPTIONS        1103
#DEFINE IS_IMPORT_BUILD_OPTION          1104
#DEFINE IS_FILES                        1200
#DEFINE IS_TEMPLATE                     1201
#DEFINE IS_BROWSE_FOR_FOLDER            1202
#DEFINE IS_BASIC_SOURCE                 1300
#DEFINE IS_INCLUDE                      1301
#DEFINE IS_RESOURCE                     1302
#DEFINE IS_MISC                         1303
#DEFINE IS_ADD_NEW_FILE                 2000
#DEFINE IS_ADD_EXISTING_FILE            2001
#DEFINE IS_ADD_NEW_MODULE               2002
#DEFINE IS_ADD_EXISTING_MODULE          2003
#DEFINE IS_OPEN_PROJECT                 2004
#DEFINE IS_FILE_EXISTS_IN_PROJECT       3000
#DEFINE IS_REMOVE_FILE_FROM_PROJECT     3001
#DEFINE IS_FAILED_TO_CREATE_THE_FOLDER  3002
#DEFINE IS_FOLDER_EXISTS                3003
#DEFINE IS_PROJECT_FILE_EXISTS          3004
#DEFINE IS_FAILED_TO_CREATE_THE_FILE    3005
#DEFINE IS_WANT_TO_SAVE_CHANGES         3006
#DEFINE IS_FILE_CHANGED_OUTSIDE_EDITOR  3007
#DEFINE IS_REOPEN_THE_FILE              3008

Const InternalStrings=	!"\13\10" & _
								!"[Internal]\13\10" & _
								!"1=Could not find\13\10" & _
								!"100=File\13\10" & _
								!"101=Project\13\10" & _
								!"1000=Find\13\10" & _
								!"1001=Next\13\10" & _
								!"1002=Previous\13\10" & _
								!"1003=Replace...\13\10" & _
								!"1004=Region searched\13\10" & _
								!"1005=Replacements done.\13\10" & _
								!"1006=Project Files searched\13\10" & _
								!"1007=Region searched%c%cFind%c  Founds: %d%c  Repeats: %d%c%cBuild%c  Errors: %d%c  Warnings: %d\13\10" & _
								!"1008=Project Files searched%c%cFind%c  Files: %d%c  Founds: %d%c  Repeats: %d%c%cBuild%c  Errors: %d%c  Warnings: %d\13\10" & _
								!"1100=Tools Menu Option\13\10" & _
								!"1101=Help Menu Option\13\10" & _
								!"1102=Build Options\13\10" & _
								!"1103=Project Build Options\13\10" & _
								!"1104=Import Build Option\13\10" & _
								!"1200=Files\13\10" & _
								!"1201=Template\13\10" & _
								!"1202=Browse For Folder\13\10" & _
								!"1300=Basic Source\13\10" & _
								!"1301=Include\13\10" & _
								!"1302=Resource\13\10" & _
								!"1303=Misc\13\10" & _
								!"2000=Add New File\13\10" & _
								!"2001=Add Existing File\13\10" & _
								!"2002=Add New Module\13\10" & _
								!"2003=Add Existing Module\13\10" & _
								!"2004=Open Project\13\10" & _
								!"3000=File exists in project.\13\10" & _
								!"3001=Remove file from project?\13\10" & _
								!"3002=Failed to create the folder:\13\10" & _
								!"3003=Folder exists. Create project anyway?\13\10" & _
								!"3004=Project file exists. Create project anyway?\13\10" & _
								!"3005=Failed to create the file:\13\10" & _
								!"3006=Want to save changes?\13\10" & _
								!"3007=File changed outside editor!\13\10" & _
								!"3008=Reopen the file?\13\10"
