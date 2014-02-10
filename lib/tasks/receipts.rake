
namespace :receipts do
  task :reconcile, [:user_public_id] => :environment do |t, args|
    users = args.any? ? User.where(public_id: args[:user_public_id].to_i) : User.all

    users.find_each do |user|
      Resque.enqueue(ReconcileReceiptsJob, user.public_id)
    end
  end
end