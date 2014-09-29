using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using Orders;
using Raven.Client;
using Raven.Client.Document;
using Raven.Client.Indexes;
using Raven.Client.Linq;

namespace Northwind
{
	internal class Program
	{
		private static DocumentStore _documentStore;

		private static void Main(string[] args)
		{
			_documentStore = new DocumentStore
			{
				Url = "http://localhost:8080",
				DefaultDatabase = "Users_Master",
				Conventions =
				{
					FailoverBehavior = FailoverBehavior.AllowReadsFromSecondariesAndWritesToSecondaries
				}
			};

			_documentStore.Initialize();

			while (true)
			{

				using (var session = _documentStore.OpenSession())
				{
					var user = session.Load<User>(1);
					user.Age++;
					Console.WriteLine(user.Name);
					session.SaveChanges();
				}
				Console.ReadLine();
			}
		}
	}


	public class User
	{
		public string Name;
		public int Age;
	}
}