require "httparty" 
require "nokogiri"
require 'dotenv/load'
require 'json'
require_relative './db/models'

# secrete token for github access
token = ENV["GITHUB_TOKEN"]

# get the first page to be scraped
pagesToScrape = ["https://github.com/orgs/vercel/repositories", 
                "https://github.com/orgs/vercel/repositories?type=all&page=2",
                "https://github.com/orgs/vercel/repositories?type=all&page=3",
                "https://github.com/orgs/vercel/repositories?type=all&page=4",
                "https://github.com/orgs/vercel/repositories?type=all&page=5",
                "https://github.com/orgs/vercel/repositories?type=all&page=6"]

puts "Getting repositories..."
counter = 1
pagesToScrape.each do |page|
  # send a get request to github
  response = HTTParty.get(page, { 
    headers: { 
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36" 
    }, 
  })

  # use nokogiri to parse the html
  document = Nokogiri::HTML(response.body)

  # get list of all repositories
  repositoriesList = document.at_css("ul.ListView-module__ul--vMLEZ")
  repositories = repositoriesList.css("li")

  # loop through all projects and get their name, link, and visbility
  repositories.each do |repo|
    # get title and link
    repoTitle = repo.at_css("a")
    repoName = repoTitle.at_css("span").text
    repoLink = repoTitle.attribute("href").value

    # get visibility (public/private)
    repoVisibility = repo.at_css("span.prc-Label-Label--LG6X").text
    repoArchived = false

    # set bool to true if repo is archived
    if repoVisibility.include?("archive")
      repoArchived = true
    end

    # add repo to database
    repo = Repository.create!(
      name: repoName,
      link: repoLink,
      visibility: repoVisibility,
      archived: repoArchived
    )

    # increment counter
    puts "Added #{counter} repositories to the database..."
    counter += 1

    # get info on pull requests for each repo
    pulls_response = HTTParty.get("https://api.github.com/repos#{repoLink}/pulls?state=all", { 
        headers: { 
          "Accept" => "application/vnd.github+json",
          "Authorization" => "Bearer #{token}",
          "X-GitHub-Api-Version" => "2022-11-28"
        }, 
      })

    pulls = JSON.parse(pulls_response.body)

    # loop through prs and get details
    pulls.each do |pr|
      pr_num = pr['number']
      pr_title = pr["title"]
      pr_updated = pr["updated_at"]
      pr_closed = pr["closed_at"]
      pr_merged = pr["merged_at"]
      pr_author = pr.dig("user", "login")

      # get additional details not available in first request
      pulls_details_response = HTTParty.get("https://api.github.com/repos#{repoLink}/pulls/#{pr_num}", { 
        headers: { 
          "Accept" => "application/vnd.github+json",
          "Authorization" => "Bearer #{token}",
          "X-GitHub-Api-Version" => "2022-11-28"
        }, 
      })  

      pr_data = JSON.parse(pulls_details_response.body)
      pr_additions = pr_data["additions"]
      pr_deletions = pr_data["deletions"]
      pr_files = pr_data["changed_files"]
      pr_commits = pr_data["commits"]

      # add pull request to database
      pull_request = PullRequest.create!(
        number: pr_num,
        title: pr_title,
        pr_updated_at: pr_updated,
        pr_closed_at: pr_closed,
        pr_merged_at: pr_merged,
        author: pr_author,
        additions: pr_additions,
        deletions: pr_deletions,
        changed_files: pr_files,
        num_of_commits: pr_commits,
        repository: repo
      )

      # get info in pr reviews
      pulls_reviews_response = HTTParty.get("https://api.github.com/repos#{repoLink}/pulls/#{pr_num}/reviews", { 
        headers: { 
          "Accept" => "application/vnd.github+json",
          "Authorization" => "Bearer #{token}",
          "X-GitHub-Api-Version" => "2022-11-28"
        }, 
      })  

      # loop through each review and get required info
      # review_list = []
      pr_reviews = JSON.parse(pulls_reviews_response.body)
      pr_reviews.each do |rev|
        # pr_review_author = rev["user"]["login"]
        # pr_review_state = rev["state"]
        # pr_submission = rev["submitted_at"]

        Review.create!(
          author: rev.dig("user", "login"),
          state: rev["state"],
          submitted_at: rev["submitted_at"],
          pull_request: pull_request
        )
      end
    end
  end
end
puts "Done!"

