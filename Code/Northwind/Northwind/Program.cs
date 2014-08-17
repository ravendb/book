using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.Remoting;
using System.Runtime.Remoting.Messaging;
using Orders;
using Raven.Abstractions.Commands;
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
			using (var session = documentStore.OpenSession())
			{
				session.Advanced.Defer(new ScriptedPatchCommandData
				{
					Key = "products/1",
					Patch = new ScriptedPatchRequest
					{
						Script = "this.UnitsInStock--;"
					}
				});
				session.SaveChanges();
			}
		}
	}

	public class User
	{
		public string Name;
	}
}
