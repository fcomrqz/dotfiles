function perf -d 'Check website performance with Lighthouse'
  command lighthouse --chrome-flags='--headless' --only-categories=performance --quiet --view $argv
end
