using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.Remoting;
using System.Runtime.Remoting.Messaging;
using Orders;
using Raven.Abstractions.Data;
using Raven.Client;
using Raven.Client.Document;

namespace Northwind
{
	internal class Program
	{
		private static void Main(string[] args)
		{
			var documentStore = new DocumentStore
			{
				Url = "http://localhost:8080",
				DefaultDatabase = "Users"
			};

			documentStore.Initialize();

			var session2 = documentStore.OpenSession();
			session2.Load<User>(1);
			session2.Dispose();

			var sp = Stopwatch.StartNew();

			using (var bulkInsert = documentStore.BulkInsert())
			{
				foreach (var i in Enumerable.Range(0, 50 * 1000))
				{
					User user = new User
					{
						Name = "Hello " + i
					};
					bulkInsert.Store(user);
				}
			}
			
			sp.Stop();

			Console.WriteLine(sp.ElapsedMilliseconds);
			Console.WriteLine(sp.Elapsed);
		}
	}

	public class User
	{
		public string Name;
	}
}
