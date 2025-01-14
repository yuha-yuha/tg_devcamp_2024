class PostsController < ApplicationController
  def new
    @post = current_user.posts.build
    @post.products.build
  end

  def create
    @post = current_user.posts.build(post_params)
    
    if @post.save
      flash[:success] = "投稿できました！"
      redirect_to new_post_path
    else
      flash[:danger] = "投稿できませんでした！入力内容を確かめてください！"
      render :new
    end
  end

  private

  def post_params
    params.require(:post).permit(:convenience_store_type, :store_name, products_attributes: [:id, :name, :content, :_destroy])
  end
end
