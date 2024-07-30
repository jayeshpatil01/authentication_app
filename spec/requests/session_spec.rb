require 'rails_helper'

describe "Sessions API", type: :request do
  describe "POST /sessions" do
    it 'creates a new user session when user is authenticated' do
      user = FactoryBot.create(:user, email: 'test@test.com', password: 'password', password_confirmation: 'password')

      post '/sessions', params: { user: {email: user.email, password: 'password', password_confirmation: 'password'} }

      expect(JSON.parse(response.body)["status"]).to eq("created")
    end

    it 'fails to create user session when user is not authenticated' do
      user = FactoryBot.create(:user, email: 'test@test.com', password: 'password', password_confirmation: 'password')

      post '/sessions', params: { user: {email: user.email, password: 'password1', password_confirmation: 'password'} }

      expect(JSON.parse(response.body)["status"]).to eq(401)
    end
  end
end
