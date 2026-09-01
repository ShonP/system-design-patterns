# System Designs

Full end-to-end system design labs. Each lab focuses on a single product
or service and walks through requirements, architecture, data model, and
scaling tradeoffs.

## Labs in this section

| Lab | Focus |
|---|---|
| [`ad-click-aggregator/`](./ad-click-aggregator/) | Real-time ad click counting |
| [`airbnb/`](./airbnb/) | Two-sided marketplace (listings, bookings) |
| [`amazon-lambda/`](./amazon-lambda/) | Function-as-a-Service: cold starts, scheduling |
| [`bitly/`](./bitly/) | URL shortener with click analytics |
| [`chatgpt/`](./chatgpt/) | LLM-backed chat at scale _(docs-only for now)_ |
| [`code-deployment/`](./code-deployment/) | CI/CD and deployment orchestration |
| [`collaborative-whiteboard/`](./collaborative-whiteboard/) | Miro-style real-time canvas |
| [`discord/`](./discord/) | Real-time chat and voice with presence |
| [`distributed-cache/`](./distributed-cache/) | Distributed cache design |
| [`distributed-lock-manager/`](./distributed-lock-manager/) | Chubby-style distributed locks |
| [`dropbox/`](./dropbox/) | File sync and sharing |
| [`fb-live-comments/`](./fb-live-comments/) | Live comment streaming |
| [`fb-news-feed/`](./fb-news-feed/) | News feed ranking and delivery |
| [`fb-post-search/`](./fb-post-search/) | Full-text search over posts |
| [`flash-sale/`](./flash-sale/) | Ecommerce flash-sale bursts |
| [`gmail/`](./gmail/) | Webmail at scale |
| [`google-calendar/`](./google-calendar/) | Calendaring and invitations |
| [`google-docs/`](./google-docs/) | Real-time collaborative documents |
| [`google-search/`](./google-search/) | Web-scale search |
| [`gopuff/`](./gopuff/) | On-demand delivery logistics |
| [`instagram/`](./instagram/) | Photo-sharing feed |
| [`job-scheduler/`](./job-scheduler/) | Distributed job scheduler |
| [`key-value-store/`](./key-value-store/) | DynamoDB-style KV store |
| [`leetcode/`](./leetcode/) | Code judging system |
| [`linkedin-connections/`](./linkedin-connections/) | People-you-may-know graph |
| [`metrics-monitoring/`](./metrics-monitoring/) | Time-series metrics platform |
| [`netflix/`](./netflix/) | Video streaming + recommendations |
| [`news-aggregator/`](./news-aggregator/) | Global news aggregation |
| [`notification-system/`](./notification-system/) | Multi-channel notifications |
| [`online-auction/`](./online-auction/) | Auctions: bidding and fairness |
| [`payment-system/`](./payment-system/) | Payments: idempotency, ledgers |
| [`rate-limiter/`](./rate-limiter/) | Rate limiter (token/leaky bucket) |
| [`reddit/`](./reddit/) | Forum/feed platform |
| [`reminder-alert/`](./reminder-alert/) | Scheduled reminders at scale |
| [`robinhood/`](./robinhood/) | Brokerage backend |
| [`s3/`](./s3/) | Object storage |
| [`shopping-cart/`](./shopping-cart/) | Amazon-style shopping cart |
| [`stock-exchange/`](./stock-exchange/) | Order-matching engine |
| [`strava/`](./strava/) | Activity tracking and leaderboards |
| [`ticketmaster/`](./ticketmaster/) | Event ticketing with bursts |
| [`tinder/`](./tinder/) | Dating app: matching, swipes |
| [`top-k/`](./top-k/) | Top-K streaming analytics |
| [`typeahead-autocomplete/`](./typeahead-autocomplete/) | Search-as-you-type suggestions |
| [`uber/`](./uber/) | Ride-hailing |
| [`web-crawler/`](./web-crawler/) | Polite large-scale crawling |
| [`whatsapp/`](./whatsapp/) | Messaging at scale |
| [`yelp/`](./yelp/) | Local search |
| [`youtube/`](./youtube/) | Video platform |

Every lab follows the same skeleton: `README.md`, `references/designgurus.md`,
`CHANGELOG.md`, plus the existing `notebooks/`, `docker-compose.yml` etc.
where present.

See also:
- [`../docs/restructure-proposal.md`](../docs/restructure-proposal.md) — overall repo structure
- [`../docs/content-map.md`](../docs/content-map.md) — lesson → lab mapping
