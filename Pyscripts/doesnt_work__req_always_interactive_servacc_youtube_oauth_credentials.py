import os
import google.oauth2.credentials  
import google_auth_oauthlib.flow
import googleapiclient.discovery
import googleapiclient.errors
import pandas as pd

scopes = ["https://www.googleapis.com/auth/youtube.readonly"]

def load_cached_credentials(credentials_file):
    if os.path.exists(credentials_file):
        with open(credentials_file, "r") as file:
            return google.oauth2.credentials.Credentials(file.read(), scopes=scopes)

def authenticate_youtube_api(client_secrets_file):
    os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"

    api_service_name = "youtube"
    api_version = "v3"

    flow = google_auth_oauthlib.flow.InstalledAppFlow.from_client_secrets_file(
        client_secrets_file, scopes)
    
    print("Checking for cached credentials...")
    credentials = load_cached_credentials("credentials.json")

    if not credentials or not credentials.valid:
        print("Cached credentials not found or expired. Running OAuth 2.0 flow...")
        credentials = flow.run_local_server(port=8080)
        
        # Save the credentials to a cache file
        with open("credentials.json", "w") as credentials_file:
            credentials_file.write(credentials.to_json())

    youtube = googleapiclient.discovery.build(
        api_service_name, api_version, credentials=credentials)
    
    return youtube

def get_youtube_search_results(youtube, query, max_results=25):
    all_responses = []
    page_token = None

    while True:
        request = youtube.search().list(
            part="snippet",
            maxResults=max_results,
            q=query,
            type="video",
            pageToken=page_token
        )
        response = request.execute()
        all_responses.append(response)
        
        page_token = response.get('nextPageToken')  # Get the nextPageToken if it exists
        
        if not page_token:
            break  # Break the loop if there is no nextPageToken
    
    return all_responses

def create_dataframe_from_responses(responses):
    parsed_data = []

    for response in responses:
        items = response.get("items", [])
        for item in items:
            snippet = item.get("snippet", {})
            title = snippet.get("title", "")
            description = snippet.get("description", "")
            channel_title = snippet.get("channelTitle", "")
            parsed_data.append({"Title": title, "Description": description, "Channel Title": channel_title})

    df = pd.DataFrame(parsed_data)
    return df

def main():
    client_secrets_file = "client_secret_auth2.json"
    youtube = authenticate_youtube_api(client_secrets_file)
    response = get_youtube_search_results(youtube, "TidyX", max_results=25)
    df = create_dataframe_from_response(response)
    print(df)

if __name__ == "__main__":
    main()
