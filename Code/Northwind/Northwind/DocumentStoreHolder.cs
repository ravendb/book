using System;
using Raven.Client;
using Raven.Client.Document;
using Raven.Client.Indexes;

namespace Northwind
{
	public class DocumentStoreHolder
	{
		private readonly static Lazy<IDocumentStore> _store = new Lazy<IDocumentStore>(CreateDocumentStore);

		private static IDocumentStore CreateDocumentStore()
		{
			var documentStore = new DocumentStore
			{
				Url = "http://localhost:8080",
				DefaultDatabase = "Northwind",
			};

			documentStore.Conventions.FindIdentityProperty = prop => prop.Name == prop.DeclaringType.Name + "Id";

			documentStore.Initialize();

			//var asm = typeof (Companies_ByCountry).Assembly;
			//IndexCreation.CreateIndexes(asm, documentStore);
			return documentStore;
		}

		public static IDocumentStore Store
		{
			get { return _store.Value; }
		}
	}
}