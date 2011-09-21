ActiveAdmin.register Page do
  
  index do
    column "Title", :sortable => :title do |page|
      link_to page.title, admin_page_path(page)
    end
    column :updated_at
    column :created_at
    
    # if can? :manage, Page
      default_actions
    # end
  end
  
  show do
    h3 page.title
    div do
      simple_format page.content
    end
  end
  
  form do |f|
    f.inputs "Public Contents" do
      f.input :title
      f.input :content, :as => :ckeditor, :input_html => { :width => "76%", :cols => 0 }
    end
    f.inputs "SEO On-Page Details" do
      f.input :browser_title
      f.input :meta_keywords
      f.input :meta_description
    end
    f.buttons
  end

end