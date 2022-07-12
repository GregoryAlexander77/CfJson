<cfcomponent displayname="CfJson" hint="Cfc to convert a cf query into a JSON object." name="CfJson">
	
    <!--- 
	convertCfQuery2JsonStruct is used for telerik and other jQuery grids. The output is like so:
    {"data":[{"supplieremail":"elizabeth.novick@medtronic.com ","supplieraddress2":"Jacksonville, FL 32216","supplierid":6536,"suppliertyperef":1,"supplierphone":"(415) 518-9505","supplieraddress1":"6743 Southpoint Drive North","suppliername":"Elizabeth Novick","applicationref":"","date":"November, 20 2014 13:33:35","contractor":"Medtronic (for Visualase Products)","isactive":1}]}  
	 
	When using the convertCfQuery2JsonStruct method on the search.cfm page:
	{"data":[{"supplieremail":"eliz@test.com ","supplieraddress2":"Jacksonville, FL 98000","supplierid":6536,"suppliertyperef":1,"supplierphone":"(415) 999-9999","supplieraddress1":"6743 North Dr.","suppliername":"Fred Astair","applicationref":"","date":"November, 20 2014 13:33:35","contractor":"Xray Tech","isactive":1}]} 
	
	Here is an example of how to get the data from the server:
	// Get the notifications from the server
	jQuery.ajax({
		type: 'post', 
		url: '/cssweb/applications/contracts/ajaxCalls.cfc?method=getNotification',
		data: { // method and the arguments
			method: "getNotification",
			dateTime: "hello"
		},
		dataType: "json",  
		success: result, // calls the result function.
		
		error: function(ErrorMsg) {
		   console.log('Error' + ErrorMsg);
		}
	});
	
	An individual item can be found like so: alert(result.data[0]['suppliername']); 
	
	Or using a simple loop with the column name of the field:
	for(var i=0; i < result.data.length; i++){
		// Get the data held in the row in the array. 
		alert(result.data[i]['notification'])
	}
	
	A bit more complex is something like this, but you will probably never need it:
	Using a for item key loop:
	function result(result) {
		var item, key;
		for (item in result.data) {
			for (key in result.data[item]) {
				alert(result.data[item][key]);
			}
		}  
	} 
	
	Using a typical for loop with an index:
	function result(result){
		// Loop thru the outer object (data)
		for(var i=0; i < result.data.length; i++){
			// Get the data held in the row in the array. 
			var obj = result.data[i];
			// Create an inner for loop
			for(var key in obj){
				// Set the values. 
				var attrName = key;
				var attrValue = obj[key];
				//your condition goes here then append it if satisfied
				//alert(attrName);
			}
		}
	}
	
	Or you can use a jQuery each function on the inner object:
	function result(result){
		// Loop thru the outer object (data)
		for(var i=0; i < result.data.length; i++){
			var obj = result.data[i];
			// For the inner object, we will use the jQuery each function
			$.each(obj, function( key, value ) {    
				alert(value);
			});
		}
	}
	
	--->
    
    <cffunction name="convertCfQuery2JsonStruct" access="public" output="true" hint="convert a ColdFusion query object into to array of structures returned as a json array.">
    	<cfargument name="queryObj" type="query" required="true">
        <cfargument name="contentType" type="string" required="true">
        <cfargument name="includeDataHandle" type="boolean" required="false" default="true">
        <cfargument name="dataHandleName" type="string" required="false" default="data">
        <cfargument name="includeTotal" type="boolean" required="false" default="false">
        <!--- Optional arguments to over ride the total which is used when the grids use serverside paging. ---> 
        <cfargument name="overRideTotal" type="boolean" required="false" default="false">
        <cfargument name="newTotal" type="any" default="false" hint="On grids that use serverside paging on kendo grids, we need to override the total.">
        <!--- Optional arguments to enable the function to clean up the HTML in the notes column for the grid. Without these arguments, the html which formats the data will also be displayed in the grid. --->
        <cfargument name="removeStringHtmlFormatting" type="boolean" required="false" default="true">
        <!--- Note: if you are trying to clean strings, it will fail if the datatype is anything other than a string. You must also provide the column name that you want to clean. ---> 
        <cfargument name="columnThatContainsHtmlStrings" type="string" required="false" default="">
        <cfargument name="convertColumnNamesToLowerCase" type="boolean" default="false" hint="Because Javascript is case sensitive, you may just want to convert everything to lower case.">
			
		<!--- This is revised function orginally found at
		https://adrianmoreno.com/2012/05/11/arraycollectioncfc-a-custom-json-renderer-for-coldfusion-queries.html
		--->

		<cfset var rs = {} /> <!--- implicit structure creation --->
		<cfset rs.results = [] /> <!--- implicit array creation --->
        <!--- Get the columns. ---> 
        <cfset rs.columnList = lCase(listSort(queryObj.columnlist, "text" )) />
        <cfif not convertColumnNamesToLowerCase>
        	<!--- Get the column label, which is the actual name of the column that is not forced into uppercase as the columnList is. Note: the getMeta() function will return a two column array object with the numeric index along with the value. We need to convert this into a list. --->
			<cfset realColumnList = arrayToList(queryObj.getMeta().getcolumnlabels())>
        </cfif>
        
		<!--- Loop over the query object and build a structure of arrays --->
		<cfloop query="queryObj">
        	<!--- Create a temporary structure to hold the data. --->
			<cfset rs.temp = {} />
            <!--- Loop thru the columns. --->
			<cfloop list="#rs.columnList#" index="rs.col">
            	<!--- To remove any formatting and get the string, we will use a Java object to turn an html object into a valid xml doc, and then use xml processing to get to the underlying string. --->
                <cfif convertColumnNamesToLowerCase>
                	<!--- Get the lower cased column name (it was forced into a lower case up above). --->
                    <cfset columnName = rs.col>
        		<cfelse>
                	<!--- Find the index in our realColumnList --->
        			<cfset realColumnNameIndex = listFindNoCase(realColumnList, rs.col)>
                    <!--- Get at the value. ---> 
        			<cfset columnName = listGetAt(realColumnList, realColumnNameIndex)>
                </cfif>                
                <cfset columnValue = queryObj[rs.col][queryObj.currentrow]>
				<cfif removeStringHtmlFormatting>
                	<cfif columnName eq columnThatContainsHtmlStrings>
                    	<cfset firstPass = getStringFromHtml(columnValue)>
                        <!--- We have to do two passes here unfortunately. The first pass returns a string with the em tags, the 2nd pass should clear all formatting. Will revisit this when I have more time.  --->
                        <cfset columnValue = getStringFromHtml(firstPass)>
                    </cfif>
                </cfif>
				<cfset rs.temp[columnName] = columnValue />
			</cfloop>
			<cfset arrayAppend( rs.results, rs.temp ) />
		</cfloop>
        
        <!--- Build the final structure. ---> 
		<cfset rs.data = {} />
        
		<!--- Include the data handle if needed --->
		<cfif includeDataHandle>
			<cfset rs.data[dataHandleName] = rs.results />
		<cfelse>
			<cfset rs.data = rs.results />
		</cfif>
        
        <!--- Return the recordcount. This is needed on certain grids to display the total number of records. --->
        <cfif includeTotal>
        	<cfif overRideTotal>
            	<!--- Note: on virtual grids, when you don't include the total (which other than debugging, is never the case, there will be an error here (can't convert 'total' to a number). If debugging, put some random numeric value here.  --->
            	<cfset rs.data["total"] = newTotal>
            <cfelse>
        		<cfset rs.data["total"] = queryObj.recordcount>
            </cfif>
        </cfif>
        
		<cfreturn serializeJSON(rs.data) />
	</cffunction>
				
	<cffunction name="convertHqlQuery2JsonStruct" access="public">
		<cfargument name="hqlQueryObj" type="array" required="true" hint="Include a variable that contains the HQL data. This should be a HQL query with the mapped column names (ie SELECT new Map (UserId, ...)">
		<cfargument name="includeDataHandle" type="boolean" required="false" default="true" hint="Some libraries and widgets need a data handle in front of the data.">
		<cfargument name="dataHandleName" type="string" required="false" default="data">
		<cfargument name="includeTotal" type="boolean" required="false" default="false">
		<!--- Optional arguments to over ride the total which is used when the grids use serverside paging. ---> 
		<cfargument name="overRideTotal" type="boolean" required="false" default="false">
		<cfargument name="newTotal" type="any" default="false" hint="On grids that use serverside paging on kendo grids, we need to override the total.">
		
		<!--- I revised this function that was orginally found at
		https://adrianmoreno.com/2012/05/11/arraycollectioncfc-a-custom-json-renderer-for-coldfusion-queries.html
		--->
		<!---Create the outer structure--->
		<cfset json.data = {} />

		<!--- Include the data handle if needed --->
		<cfif includeDataHandle>
			<cfset json.data[dataHandleName] = hqlQueryObj />
		<cfelse>
			<cfset json.data = hqlQueryObj />
		</cfif>

		<!--- Return the recordcount. This is needed on certain grids to display the total number of records. --->
		<cfif includeTotal>
			<cfif overRideTotal>
				<!--- Note: on virtual grids, when you don't include the total (which other than debugging, is never the case, there will be an error here (can't convert 'total' to a number). If debugging, put some random numeric value here.  --->
				<cfset json.data["total"] = newTotal>
			<cfelse>
				<cfset json.data["total"] = arrayLen(hqlQueryObj) />
			</cfif>
		</cfif>
		<!--- Return it. --->		
		<cfreturn serializeJson(json.data)>
	</cffunction>
			
	<!--- This makes a json string more readable. It is used to display the JSON-LD. This was found at http://chads-tech-blog.blogspot.com/2016/10/format-json-string-in-coldfusion.html --->
	<cffunction name="formatJson" hint="Indents JSON to make it more readable">
		<cfargument name="JSONString" default="" hint="JSON string to be formatted">
		<cfargument name="indentCharacters" default="#Chr(9)#" hint="Character(s) to use for indention">

		<cfset local.inQuotes = false>
		<cfset local.indent = 0>
		<cfset local.returnString = "">
		<cfset local.stringLength = Len(arguments.JSONString)>
		<cfloop index="i" from="1" to="#local.stringLength#">
			<cfset local.currChar = Mid(arguments.JSONString, i, 1)>
			<cfif i lt local.stringLength - 1>
				<cfset local.nextChar = Mid(arguments.JSONString, i + 1, 1)>
			<cfelse>
				<cfset local.nextChar = "">
			</cfif>
			<cfif local.currChar eq '"'>
				<cfset local.inQuotes = !local.inQuotes>
			</cfif>
			<cfif local.inQuotes>
				<cfset local.returnString = local.returnString & local.currChar>
			<cfelse>
				<cfswitch expression="#local.currChar#">
					<cfcase value="{">
						<cfset local.indent = local.indent + 1>
						<cfset local.returnString = local.returnString & "{" & chr(10) & chr(13) & RepeatString(arguments.indentCharacters, local.indent)>
					</cfcase>
					<cfcase value="}">
						<cfset local.indent = local.indent - 1>
						<cfset local.returnString = local.returnString & chr(10) & chr(13) & RepeatString(arguments.indentCharacters, local.indent) & "}">
						<cfif local.nextChar neq ",">
							<cfset local.returnString = local.returnString & chr(10) & chr(13)>
						</cfif>
					</cfcase>
					<cfcase value="," delimiters="Chr(0)">
						<cfset local.returnString = local.returnString & "," & chr(10) & chr(13) & RepeatString(arguments.indentCharacters, local.indent)>
					</cfcase>
					<cfcase value=":">
						<cfif local.nextChar neq " ">
							<cfset local.returnString = local.returnString & ": ">
						</cfif>
					</cfcase>
					<cfdefaultcase>
						<cfset local.returnString = local.returnString & local.currChar>
					</cfdefaultcase>
				</cfswitch>
			</cfif>
		</cfloop>

		<cfreturn trim(local.returnString)>
	</cffunction>


</cfcomponent>
