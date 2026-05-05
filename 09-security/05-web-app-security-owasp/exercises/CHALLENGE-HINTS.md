# Solving Juice Shop: hint-only walkthroughs

These are not full solutions — they're "next clue if you're stuck for 10+ minutes." The point is to figure most of it out.

## Score Board (Challenge 0)
The Angular bundle has a routes module. Open browser dev tools → Sources → search the chunked JS for `score-board`. The path is what you'd guess.

## Login Admin (SQLi)
The login uses raw string concatenation. The classic `' OR 1=1--` works. Look for an admin-looking email to make it deterministic.

## DOM XSS
Search box reflects what you typed into the DOM via `innerHTML`. Try an `<iframe src="...">` or `<svg/onload>`.

## Confidential Document
There's an FTP-style file listing on a path you can guess. The `/ftp` path lists files; some have `.bak` / `.md` extensions and contain juicy info.

## Forged Feedback
The feedback form sends a `UserId` field. Client-side it's set to your own ID. ZAP proxy → modify the field to another user's ID.

## Five-star Feedback
Ratings are clamped client-side to 5. Same trick — modify the request body via ZAP proxy.

## Reset Jim's Password
Security questions have predictable hints (his birth city is in his email user account history → Google).

## Forgotten Sales Endpoint
Look at robots.txt or the sitemap. There's a deprecated route still mounted.

## Privacy Policy Inspection
A localStorage key stores feature flags. One of them is `betaSubscription`. Toggle it.

## More
Real walkthroughs live in *Pwning OWASP Juice Shop* (https://pwning.owasp-juice.shop/). Read after you've struggled.
