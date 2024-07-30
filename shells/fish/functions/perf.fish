function perf -d 'Check website performance with Lighthouse'
    command lighthouse --chrome-flags='--headless' --only-categories=performance --quiet --view $argv
    command sleep 1
    command rm *.report.html
end
