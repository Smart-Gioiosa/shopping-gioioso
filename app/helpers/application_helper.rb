module ApplicationHelper
    def title
        return t("app_name") unless content_for?(:title)
        
        "#{content_for(:title)} | #{t("app_name")}"
    end
end
