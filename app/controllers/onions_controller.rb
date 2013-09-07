class OnionsController < ApplicationController
	require 'base64'
	respond_to :json, :html

	def index
		@onions = nil
		if session[:SessionKey] && session[:UserKey]
			user_hash = Session.user_hash_for_session(session[:SessionKey])
			if user_hash
				@onions = Onion.where(:HashedUser => Session.user_hash_for_session(session[:SessionKey])).order("id")
				@onions = Onion.decrypted_onions_with_key(@onions,session[:UserKey])
				respond_with({:error => "Unauthorized Access"}.as_json, :location => "/")
			else
				redirect_to("/")
			end
		else
			redirect_to("/")
		end
  end


	def show
		respond_with({:error => "Unauthorized Access"}.as_json, :location => nil)
	end


	def create
		if params[:onion] && session[:SessionKey] && session[:UserKey]
			onion = params[:onion]
			userHash = Session.user_hash_for_session(session[:SessionKey])
			if userHash
        onionTitle = onion[:Title]
        onionInfo = onion[:Info]
				eTitle = Onion.aes256_encrypt(session[:UserKey], (onionTitle.length>75 ? onionTitle[0..74] : onionTitle))
				eTitle = Base64.encode64(eTitle)
				eInfo = Onion.aes256_encrypt(session[:UserKey], (onionInfo.length>800 ? onionInfo[0..799] : onionInfo))
				eInfo = Base64.encode64(eInfo)
				if params[:Id]
					/ Edit Onion /
					@o = Onion.find(params[:Id])
					@o.HashedTitle = eTitle
					@o.HashedInfo = eInfo
					@o.save
				else
					/ New Onion /

					@o = Onion.create(:HashedUser => userHash, :HashedTitle => eTitle, :HashedInfo => eInfo)
				end
				respond_with({:error => "Unauthorized Access"}.as_json, :location => "/onions")
				session[:SessionKey] = Session.new_session(userHash)
			else
				respond_with({:error => "Unauthorized Access"}.as_json, :location => "/")
			end
		else
			respond_with({:error => "Unauthorized Access"}.as_json, :location => "/")
		end
	end


	def delete
		respond_with({:error => "Unauthorized Access"}.as_json, :location => nil)
	end


	def getAllOnions
		if params[:SessionKey]
			@user_hash = Session.user_hash_for_session(params[:SessionKey])
			if @user_hash
				@onions = Onion.where(:HashedUser => @user_hash)
				respond_with({:Onions => @onions, :SessionKey => Session.new_session(@user_hash)}.as_json, :location => nil)
			else
				respond_with({:error => "No User for Session"}.as_json, :location => nil)
			end
		else
			respond_with({:error => "No Session Key"}.as_json, :location => nil)
		end
	end


	def addOnion
		if params[:SessionKey]
			@user_hash = Session.user_hash_for_session(params[:SessionKey])
			if @user_hash
				@onion = Onion.create(:HashedUser => @user_hash, :HashedTitle => params[:HashedTitle], :HashedInfo => params[:HashedInfo])
				respond_with({:NewOnion => @onion, :SessionKey => Session.new_session(@user_hash)}.as_json, :location => nil)
			else
				respond_with({:error => "No User for Session"}.as_json, :location => nil)
			end
		else
			respond_with({:error => "No Session Key"}.as_json, :location => nil)
		end
	end


	def editOnion
		if params[:SessionKey]
			@user_hash = Session.user_hash_for_session(params[:SessionKey])
			if @user_hash
				@onion = Onion.find(params[:Id])
				@onion.HashedTitle = params[:HashedTitle]
				@onion.HashedInfo = params[:HashedInfo]
				if @onion.save
					respond_with({:Status => "Success", :SessionKey => Session.new_session(@user_hash)}.as_json, :location => nil)
				else
					respond_with({:error => "Onion failed to Save."}.as_json, :location => nil)
				end
			else
				respond_with({:error => "No User for Session"}.as_json, :location => nil)
			end
		else
			respond_with({:error => "No Session Key"}.as_json, :location => nil)
		end
	end


	def delete_onion
		if params[:SessionKey]
			@user_hash = Session.user_hash_for_session(params[:SessionKey])
			if @user_hash
				@onion = Onion.find(params[:Id]).destroy
				respond_with({:Status => "Success", :SessionKey => Session.new_session(@user_hash)}.as_json, :location => nil)
			else
				respond_with({:error => "No User for Session"}.as_json, :location => nil)
			end
		else
			respond_with({:error => "No Session Key"}.as_json, :location => nil)
		end
	end


	def deleteOnionWeb
		if session[:SessionKey]
			userHash = Session.user_hash_for_session(session[:SessionKey])
			if userHash && params[:OnionId]
				@onion = Onion.find(params[:OnionId])
				if @onion.HashedUser == userHash
					@onion.destroy
					session[:SessionKey] = Session.new_session(userHash)
					redirect_to("/onions")
				else
					/ No Permission /
				end
			else
				/ No Permission /
			end
		else
			/ No Permission /
		end
	end

end