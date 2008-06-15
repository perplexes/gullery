# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def show_page_title
    !@user.nil? && !@user.company.blank? ? @user.company : 'gullery photo gallery'
  end

  def show_page_nav
    user = User.find(:first)
    return 'gullery photo gallery' if user.nil?
    nav = link_to(user.company, :controller => '/')
    nav += ' ' + content_tag(:small, link_to((@project.name), projects_url(:action => 'show', :id => @project))) if @project
    nav
  end
  
  def selected(path)
    request.path_parameters.values.any?{|pp| pp == path} ? 'selected' : ''
  end
  
  def mailto(email)
    link_to email, "mailto:#{email}"
  end
  
  # Hack for Markaby and Rails 2.0
  def string_path(string)
    string
  end
  
end
