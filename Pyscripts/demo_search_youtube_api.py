import os
import google_auth_oauthlib.flow
import googleapiclient.discovery
import googleapiclient.errors
import pandas as pd

scopes = ["https://www.googleapis.com/auth/youtube.readonly"]

def authenticate_youtube_api(client_secrets_file):
    os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"

    api_service_name = "youtube"
    api_version = "v3"

    flow = google_auth_oauthlib.flow.InstalledAppFlow.from_client_secrets_file(
        client_secrets_file, scopes)
    credentials = flow.run_local_server(port=8080)
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

# def main():
    client_secrets_file = "Pyscripts/client_secret_auth2.json"
    youtube = authenticate_youtube_api(client_secrets_file)
    responses = get_youtube_search_results(youtube, "TidyX", max_results=50)
#     df = create_dataframe_from_responses(responses)
#     print(df)
# 
# if __name__ == "__main__":
#     main()
