# Per-page layout changes:
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false
page '/', layout: 'layout'
page '/learn/*', layout: 'guide', data: { sidebar: 'learn/sidebar' }
page '/guides/*', layout: 'guide', data: { sidebar: 'guides/sidebar' }
page '/blog/*', data: { sidebar: 'blog/sidebar' }

def next?
  ENV['NEXT'] == 'true'
end

set :api_base_url, "http://www.rubydoc.info/#{next? ? 'github/rom-rb' : 'gems'}"

set :api_url_template, "#{config.api_base_url}/%{project}/ROM/%{path}"
set :api_anchor_url_template, "#{config.api_base_url}/%{project}/ROM/%{path}#%{anchor}"

# Helpers
helpers do
  def nav_link_to(link_text, url, options = {})
    root = options.delete(:root)
    is_active = (!root && current_page.url.start_with?(url)) ||
                current_page.url == url
    options[:class] ||= ''
    options[:class] << '--is-active' if is_active
    link_to(link_text, url, options)
  end

  def learn_root_resource
    sitemap.find_resource_by_destination_path('learn/index.html')
  end

  def guides_root_resource
    sitemap.find_resource_by_destination_path('guides/index.html')
  end

  def sections_as_resources(resource)
    sections = resource.data.sections
    sections.map do |s|
      destination_path = resource.url + "#{s}/index.html"
      sitemap.find_resource_by_destination_path(destination_path)
    end
  end

  def head_title
    current_page.data.title.nil? ? 'ROM' : "ROM - #{current_page.data.title}"
  end

  def copyright
    "&copy; 2014-#{Time.now.year} Ruby Object Mapper."
  end

  def design_by
    url = 'https://github.com/angeloashmore'
    "Design by #{link_to '@angeloashmore', url}."
  end

  def logo_by
    url = 'https://github.com/kapowaz'
    "Logo by #{link_to '@kapowaz', url}."
  end
end

# General configuration
set :build_dir, 'docs'
set :layout, 'content'
set :css_dir, 'assets/stylesheets'
set :js_dir, 'assets/javascripts'

require 'middleman-core/renderers/redcarpet'

class MarkdownRenderer < Middleman::Renderers::MiddlemanRedcarpetHTML
  DEFAULT_OPTS = { tables: true, autolink: true, gh_blockcode: true, fenced_code_blocks: true }

  def initialize(options = {})
    super(options.merge(DEFAULT_OPTS))
  end

  def link(link, title, content)
    if content.start_with?('api::')
      _, project, klass = content.split('::')
      link_to_api(project, klass, link)
    else
      super
    end
  end

  def link_to_api(project, klass, meth)
    path = klass ? klass.gsub('::', '/') : ''

    anchor = if meth.include?('#')
               "#{meth}-instance_method".gsub('#', '')
             elsif meth.include?('.')
               "#{meth}-class_method".gsub('#', '')
             end

    if anchor
      content = path.empty? ? meth : "#{path.gsub('/', '::')}#{meth}"

      link(
        config.api_anchor_url_template % { project: project, path: path, anchor: anchor },
        nil, content
      )
    else
      content = path.empty? ? "ROM::#{meth}" : "ROM::#{path.gsub('/', '::')}::#{meth}"

      link(
        config.api_url_template % { project: project, path: "#{path}/#{meth}" },
        nil, content
      )
    end
  end

  def config
    scope.config
  end
end

set :markdown_engine, :redcarpet
set :markdown, renderer: MarkdownRenderer, tables: true, autolink: true, gh_blockcode: true, fenced_code_blocks: true

set :disqus_embed_url, 'https://rom-rb-blog.disqus.com/embed.js'

activate :blog,
  prefix: 'blog',
  layout: 'blog_article',
  permalink: '{title}.html',
  paginate: true,
  tag_template: 'blog/tag.html'

activate :syntax, css_class: 'syntax'

activate :directory_indexes

activate :external_pipeline,
  name: :webpack,
  command: build? ? './node_modules/webpack/bin/webpack.js --bail' : './node_modules/webpack/bin/webpack.js --watch -d',
  source: '.tmp/dist',
  latency: 1

if next?
  activate :deploy do |deploy|
    deploy.deploy_method = :rsync
    deploy.host   = 'next.rom-rb.org'
    deploy.path   = '/var/www/next.rom-rb.org'
    deploy.clean  = true
  end
else
  activate :deploy, deploy_method: :git
end

# Development-specific configuration
configure :development do
  activate :livereload
end
