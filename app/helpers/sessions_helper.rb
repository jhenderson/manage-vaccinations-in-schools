module SessionsHelper
  def pluralize_child(count)
    count.zero? ? "No children" : pluralize(count, "child")
  end
end
