# R-Ladies YouTube Video Feed Dashboard

<!-- badges: start -->
[![rladies-videos-bot](https://github.com/ivelasq/rladies-video-feed/actions/workflows/rladies-videos-bot.yaml/badge.svg)](https://github.com/ivelasq/rladies-video-feed/actions/workflows/rladies-videos-bot.yaml)
<!-- badges: end -->
https://ivelasq.rbind.io/blog/automated-youtube-dashboard/
This is a [flexdashboard](https://pkgs.rstudio.com/flexdashboard/) showing the most recent R-Ladies YouTube videos.

![Screenshot of the dashboard showing the latest YouTube videos from R-Ladies YouTube channels](image.png)

## How it works

mermaid code chunk

```mermaid
graph TB
    subgraph "Github actions"
        R_process  -->|fetch pre-proccessed data| google_sheets["google_sheets"]
        R_process -->|find new videos| youtube_api{youtube_api}
        R_process -->|make new descriptions| openai_api{openai_api}
        google_sheets --> R_report["Flexdashboard Dashboard"]
        youtube_api --> R_report
        openai_api --> R_report
    end
```